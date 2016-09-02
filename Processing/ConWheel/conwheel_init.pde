/*
  Project:     Connection Wheel
  Name:        conwheel.pde
  Purpose:     Displays connection networks on a wheel. Initialization routines.
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik 
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2014-11-06
  Modified:    2016-07-20 help removed
      
  Comment:     -
  
  Uses:        Modules: conwheel.pde, conwheel_animation.pde, conwheel_events.pde, 
               conwheel_gui_classes.pde, conwheel_io.pde, conwheel_network.pde
  
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


void initConfiguration() {
  node_font = createFont(node_font_name, node_font_size);
  textFont(node_font);
  node_font_height = textAscent() + textDescent();
  
  version_font = createFont(version_font_name, version_font_size);
}


void initGraph() {
  current_position = 0;
  rot_angle = 0;
  grid = TWO_PI/node_count;
  
  calcGraphDimensions();
}

void calcGraphDimensions() {
  int name_max_index = (Integer) node2index.get(name_length_max_pointer);
  Node node = (Node) nodes.get(name_max_index);
  
  textFont(node_font);
  float node_name_length_max = textWidth(node.name);
  
  wheel_anchor_radius = wheel_diameter/2 - node_name_length_max - anchor_name_distance - anchor_diameter/2 - wheel_margin;
  wheel_anchor_radius_inner = wheel_anchor_radius - anchor_diameter/2;
  detect_inner_radius2 = wheel_anchor_radius_inner * wheel_anchor_radius_inner;
  detect_outer_radius2 = wheel_diameter * wheel_diameter / 4;
  bezier_radius = max(wheel_anchor_radius_inner - curvature,0);
  wheel_axis_x = infozone_width + wheel_diameter/2;
  wheel_axis_y = wheel_diameter/2;
  
  ellipseMode(CENTER);
}


void initAnimation() {
  // turn active node in zero position
  int active_node_index = (Integer) node2index.get(active_node);
  Node node = (Node) nodes.get(active_node_index);
  int target_position = node.position;
  int start_position = current_position;
  wheel.start_animation(start_position,target_position);
}