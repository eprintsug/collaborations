/*
  Project:     Connection Wheel
  Name:        conwheel_graph_classes.pde
  Purpose:     Displays connection networks on a wheel. Defines classes for graph.
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik 
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2014-10-06
  Modified:    2016-07-20  flipping labels
      
  Comment:     -
  
  Uses:        Modules: conwheel.pde, conwheel_animation.pde, conwheel_events.pde, 
               conwheel_gui_classes.pde, conwheel_init.pde, conwheel_io.pde, conwheel_network.pde
  
  Copyright:   2014, University of Zurich, IT Services
  License:     The Connection Wheel code is Open Source Software. It is released under the 
               GNU GPL (General Public License). For more information, see 
               http://www.opensource.org/licenses/gpl-license.php
               
               THE Connection Wheel code IS PROVIDED TO YOU "AS IS", AND WE MAKE NO EXPRESS 
               OR IMPLIED WARRANTIES WHATSOEVER WITH RESPECT TO ITS FUNCTIONALITY, OPERABILITY, 
               OR USE, INCLUDING, WITHOUT LIMITATION, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, 
               FITNESS FOR A PARTICULAR PURPOSE, OR INFRINGEMENT. WE EXPRESSLY DISCLAIM ANY 
               LIABILITY WHATSOEVER FOR ANY DIRECT, INDIRECT, CONSEQUENTIAL, INCIDENTAL OR SPECIAL 
               DAMAGES, INCLUDING, WITHOUT LIMITATION, LOST REVENUES, LOST PROFITS, LOSSES RESULTING 
               FROM BUSINESS INTERRUPTION OR LOSS OF DATA, REGARDLESS OF THE FORM OF ACTION OR LEGAL 
               THEORY UNDER WHICH THE LIABILITY MAY BE ASSERTED, EVEN IF ADVISED OF THE POSSIBILITY 
               OR LIKELIHOOD OF SUCH DAMAGES. 
               
               By using this code, you agree to the specified terms.             
  
  Requires:    Processing Development Environment (PDE), http://www.processing.org/
  Generates:   The PDE exports (menu File > Export) code and data to a web-export directory. 
  
==========================================================================================================================  
*/

class Node {
  String id;
  int position;       // sorted index
  int item_count;
  int click_count;
  float diameter;
  String name;
  String link;
  float node_name_width;
  int status;
  color current_color;
  int edgegroup_refs_count;
  ArrayList<String> edgegroup_refs;
  HashMap edgegroup_refs_hm;
  
  // constructor
  Node(String id_init, int position_init, int item_count_init, String name_init, String link_init) {
    id = id_init;
    position = position_init;
    item_count = item_count_init;
    diameter = anchor_diameter + sqrt(item_count);
    click_count = 0;
    name = name_init;
    link = link_init;
    node_name_width = textWidth(name);
    status = STATUS_NORMAL;
    current_color = node_color_normal;
    edgegroup_refs_count = 0;
    edgegroup_refs = new ArrayList<String>();
    edgegroup_refs_hm = new HashMap();
  }
  
  // methods
  void draw() {
    float angle = grid * position;
    
    pushMatrix();
    rotate(angle);
    
    switch(status) {
      case STATUS_HOVERED:
        current_color = node_color_hover;
        fill(current_color);
        break;
      case STATUS_SELECTED:        
        current_color = node_color_selected;
        fill(current_color); 
        break;
      case STATUS_ACTIVE:
        current_color = node_color_active;
        fill(current_color);
        break;
      default:
        current_color = node_color_normal;
        noFill();
        break;
    }
    stroke(current_color);
    strokeWeight(1.0);
    
    ellipse(-wheel_anchor_radius,0,diameter,diameter);
    // ellipse(-wheel_anchor_radius,0,anchor_diameter,anchor_diameter);
    
    fill(current_color);
    
    float angle_eff = (rot_angle + angle) % TWO_PI;
    if (angle_eff > PI / 2 && angle_eff < 1.5 * PI )
    {
      pushMatrix();
      translate(-wheel_anchor_radius-anchor_name_distance,0);
      rotate(PI);
      textAlign(LEFT,CENTER);
      text(name,0,0);
      popMatrix();
    }
    else 
    {
      textAlign(RIGHT,CENTER);
      text(name,-wheel_anchor_radius-anchor_name_distance,0);
    }
    popMatrix();
  }

  boolean detectHover(int mouse_x, int mouse_y) {
    boolean hover = false;
    float angle = grid * position;
    
    float mouse_rel_x = mouse_x - wheel_axis_x;
    float mouse_rel_y = mouse_y - wheel_axis_y;
    float mouse_radius2 = mouse_rel_x * mouse_rel_x + mouse_rel_y * mouse_rel_y;

    if (mouse_radius2 >= detect_inner_radius2 && mouse_radius2 <= detect_outer_radius2) {
      // rotate mouse coord
      float cos_angle = cos(rot_angle + angle);
      float sin_angle = sin(rot_angle + angle);
      
      float mouse_rot_x = mouse_rel_x * cos_angle + mouse_rel_y * sin_angle;
      float mouse_rot_y = mouse_rel_x * sin_angle - mouse_rel_y * cos_angle;
      
      float detect_x1 = -wheel_anchor_radius - anchor_name_distance - node_name_width;
      float rect_width = node_name_width + anchor_name_distance + anchor_diameter/2;
      float detect_x2 = detect_x1 + rect_width;
      float detect_y1 = -node_font_height/2 - 2;
      float detect_y2 = node_font_height/2 + 2;
      
      if (mouse_rot_x >= detect_x1 && mouse_rot_x <= detect_x2 && mouse_rot_y >= detect_y1 && mouse_rot_y <= detect_y2) {
        hover = true;
      } 
    }
    return hover;
  }
 
  void updatePosition(int position_update) {
    position = position_update;
  }
  
  void setActiveStatus() {
    status = STATUS_ACTIVE;
  }
  
  void resetStatus() {
    if (status != STATUS_ACTIVE) {
      status = STATUS_NORMAL;
    }
  }
  
  void updateStatus(int status_update) {
    if (status != STATUS_ACTIVE) {  
      status = status_update;
    }
  }
  
  void updateClickCount() {
    if (click_count == 0) {
      click_count = 1;
    }
  }
  
  void resetClickCount() {
    click_count = 0;
  }
  
  void addEdgeGroupRef(String ref) {
    if (edgegroup_refs_hm.get(ref) == null) {
      edgegroup_refs.add(ref);
      edgegroup_refs_hm.put(ref, edgegroup_refs_count);
      edgegroup_refs_count++;
    }
  }
}

class Edge {
  String id;
  String from;
  String to;
  String ref;
  int from_index;
  int to_index;
  int status;              // 0 = normal, 1 = hover, 2 = selected
  Node node_from;
  Node node_to;
  
  // constructor
  Edge(String id_init, String from_init, String to_init, String ref_init, int from_index_init, int to_index_init) {
    id = id_init;
    from = from_init;
    to = to_init;
    ref = ref_init;
    from_index = from_index_init;
    to_index = to_index_init;
    status = 0;
    node_from = (Node) nodes.get(from_index);
    node_to = (Node) nodes.get(to_index);
  }
  
  // methods
  void draw() {
    float from_angle = grid * node_from.position;
    float to_angle = grid * node_to.position;
    
    float from_r = (node_from.diameter - anchor_diameter)/2;
    float to_r = (node_to.diameter - anchor_diameter)/2;
    
    switch(status) {
      case STATUS_HOVERED:
        stroke(node_color_hover);
        strokeWeight(edge_weight_hover);
        break;
      case STATUS_SELECTED:
        stroke(node_color_selected);
        strokeWeight(edge_weight_selected);
        break;
      default:
        stroke(edge_color);
        strokeWeight(edge_weight_normal);
        break;
    }
    noFill();
     
    // some trigonometry
    float cos_from = -cos(from_angle);
    float sin_from = -sin(from_angle);
    float from_x = (wheel_anchor_radius_inner - from_r) * cos_from;
    float from_y = (wheel_anchor_radius_inner - from_r) * sin_from;
    float from_bezier_x = bezier_radius * cos_from;
    float from_bezier_y = bezier_radius * sin_from;
    
    float cos_to = -cos(to_angle);
    float sin_to = -sin(to_angle);
    float to_x = (wheel_anchor_radius_inner - to_r) * cos_to;
    float to_y = (wheel_anchor_radius_inner - to_r) * sin_to;
    float to_bezier_x = bezier_radius * cos_to;
    float to_bezier_y = bezier_radius * sin_to; 
    
    bezier(from_x,from_y, from_bezier_x, from_bezier_y, to_bezier_x, to_bezier_y, to_x, to_y);
  }
  
  void resetStatus() {
    status = STATUS_NORMAL;
  }
  
  void updateStatus(int status_update) {
    status = status_update;
  }
}

class EdgeGroup {
  String ref;
  ArrayList<Integer> edge_indexes;
  
  EdgeGroup(String ref_init) {
    ref = ref_init;
    edge_indexes = new ArrayList<Integer>();
  }
  
  void addEdge(int edge_index) {
    edge_indexes.add(edge_index);
  }
}