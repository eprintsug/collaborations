/* @pjs crisp="true"; pauseOnBlur="true"; */
/*
  Project:     Connection Wheel
  Name:        conwheel.pde
  Purpose:     Displays connection networks on a wheel.
  
               ConWheel reads a network graph and displays it on an interactive wheel.
               Graph data, defined as a set of nodes and edges, and configuration parameters are read from 
               two XML files, e.g. data.xml and configuration.xml. 
               About the detailed format and description of the files see module conwheel_io.pde 
  
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik 
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2014-10-06
  Modified:    2016-06-20  initial resize
               2016-07-19  improved wheel acceleration / deceleration
               2016-07-20  flipping labels / help removed
      
  Comment:     -
  Todo:        tooltips?
               multilingual callback base url?
  
  Uses:        Modules: conwheel_animation.pde, conwheel_events.pde, 
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

/*
  Constants
*/
final int STATUS_NORMAL = 0;
final int STATUS_HOVERED = 1;
final int STATUS_SELECTED = 2;
final int STATUS_ACTIVE = 3;

final int STATUS_STOPPED = 0;
final int STATUS_ANIMATE = 1;

final int STATUS_ACCELERATE = 1;
final int STATUS_DECELERATE = -1;
final int STATUS_CONSTANTSPEED = 0;

final int HOVER_HELP = 1000000;
final int HOVER_ITEMS_LINK = 1000001;
final int HOVER_NODE_LINK = 1000002;

final int EDGE_LIMIT = 5000;

/* 
  Global variables
*/

String version = "ConWheel v1.0";

int wheel_diameter = 800;
int infozone_width = 80;
int wheel_margin = 10;

int applet_width;
int applet_height;

// file names
String f_configuration = "/coauthors/configuration.xml";
String f_data;

// language of applet
String language;

// Configuration parameters
String node_base_url;
String items_base_url;

// Wheel parameters
Wheel wheel;
float wheel_axis_x;
float wheel_axis_y;
float wheel_anchor_radius;
float wheel_anchor_radius_inner;
float anchor_name_distance;
float grid;
float acceleration;      // degrees
float velocity;          // degrees
float rot_angle;
int current_position;
String name_length_max_pointer;
int animation_status = STATUS_STOPPED;
int acceleration_status;
int animation_step;

// Node parameters
String active_node;
String node_font_name;
float node_font_size;
PFont node_font;
float node_font_height;
float anchor_diameter;
color node_color_normal;
color node_color_active;
color node_color_hover;
color node_color_selected;

// Edge parameters
float curvature;
float curvature_ratio;
float bezier_radius;
float edge_weight_normal;
float edge_weight_hover;
float edge_weight_selected;
color edge_color;

int node_count;
int edge_count;
int edgegroup_count;

// Graph parameters
XML xml_data;  
ArrayList nodes;
ArrayList edges;
ArrayList edgegroups;
String [] node_names;
HashMap node2index;
HashMap node_name2index;
HashMap sorted2index;
HashMap alphabet2index;
HashMap edgegroup2index;

// Hovered and selected edge groups
ArrayList<String> edgegroups_hovered;
ArrayList<String> edgegroups_selected;

// Mouse detection
float detect_inner_radius2;
float detect_outer_radius2;
int hovered_object;

// Parameters and fonts for version HUD
PFont version_font;
String version_font_name;
float version_font_size;
color version_font_color;

void setup() {
  // read applet parameters
  f_data = "/coauthors/data/" + this.param("mydata");
  
  applet_width = infozone_width + wheel_diameter;
  applet_height = wheel_diameter;
  
  node2index = new HashMap();
  node_name2index = new HashMap();
  sorted2index = new HashMap();
  alphabet2index = new HashMap();
  edgegroup2index = new HashMap();
  
  nodes = new ArrayList();
  edges = new ArrayList();
  edgegroups = new ArrayList();
  edgegroups_hovered = new ArrayList<String>();
  edgegroups_selected = new ArrayList<String>();
  
  size(880,800);
  
  loadConfiguration(f_configuration);
  initConfiguration();
  
  curvature_ratio = curvature/wheel_diameter;
  
  loadData(f_data);
  sortData();
  initGraph();
  
  wheel = new Wheel();
  
  // external JavaScript function
  getConWheelCanvasSize();
  
  initAnimation();
}

void draw() {
  hovered_object = -1;
  
  colorMode(RGB,255);
  background(255);
  smooth();
  
  // draw mouse detection part
  resetNetwork(STATUS_HOVERED);
  if (animation_status == STATUS_STOPPED) {
    for (int i = 0; i < node_count; i++) {
      Node node = (Node) nodes.get(i);
      boolean hover = node.detectHover(mouseX,mouseY);
      if (hover) {
        hovered_object = i;
        Node hovered_node = (Node) nodes.get(hovered_object);
        updateNetwork(hovered_node, STATUS_HOVERED);
        // exit loop as early as possible to improve performance
        i = node_count;
      }
    }
  }
  
  // drawing part
  pushMatrix();
  translate(wheel_axis_x,wheel_axis_y);
  rotate(rot_angle);
  
  // edges
  if (edge_count < EDGE_LIMIT || animation_status == STATUS_STOPPED)
  {
    // edges normal
    for (int i = 0; i < edge_count; i++) 
    {
      Edge edge = (Edge) edges.get(i);
      if (edge.status == STATUS_NORMAL) 
      {
        edge.draw();
      }
    }
  
    // edges hovered and selected
    for (int i = 0; i < edge_count; i++) {
      Edge edge = (Edge) edges.get(i);
      if (edge.status != STATUS_NORMAL) {
        edge.draw();
      }
    }
  }
  
  // nodes
  textFont(node_font);
  for (int i = 0; i < node_count; i++) {
    Node node = (Node) nodes.get(i);
    node.draw();
  }
 
  popMatrix();
  
  if (animation_status != STATUS_STOPPED) {
    wheel.animate();
  } else {
    drawInfoZone();
  }
  
  drawVersion();
}

void drawInfoZone() {
  color infozone_color;
  float detect_x1;
  float detect_x2;
  
  float detect_y1 = (applet_height - node_font_height) / 2 - 2;
  float detect_y2 = (applet_height + node_font_height) / 2 + 2;
  
  int hovered_node_position = -1;
  int item_count_pos_x = 10;
  int node_link_pos_x = infozone_width - anchor_name_distance - 10;
  int line_pos_y = int(node_font_height/2) + 3;
  
  int mouse_x = mouseX;
  int mouse_y = mouseY;
 
  int index = (Integer) sorted2index.get(current_position);
  Node node = (Node) nodes.get(index);
  int item_count = node.item_count;
  
  infozone_color = node.current_color;
  
  pushMatrix();
  resetMatrix();
  translate(0,wheel_axis_y);
  
  // items link
  noStroke();
  fill(infozone_color);
  textAlign(LEFT,CENTER);
  text(item_count,item_count_pos_x,0);
  stroke(infozone_color);
  strokeWeight(1.0);
  float item_count_width = textWidth(str(item_count));
  line(item_count_pos_x, line_pos_y, item_count_pos_x + item_count_width, line_pos_y);
  
  // detect mouse hover over items link
  if (mouse_x >= item_count_pos_x && mouse_x <= item_count_pos_x + item_count_width && mouse_y >= detect_y1 && mouse_y <= detect_y2) {
    hovered_object = HOVER_ITEMS_LINK;
  }
  
  // node link
  noFill();
  ellipse(node_link_pos_x, 0, node_font_height, node_font_height);
  noStroke();
  fill(infozone_color);
  float node_link_diameter = node_font_height - 4;
  ellipse(node_link_pos_x, 0, node_link_diameter, node_link_diameter);
  stroke(infozone_color);
  strokeWeight(1.0);
  line(node_link_pos_x - node_font_height/2, line_pos_y, node_link_pos_x + node_font_height/2, line_pos_y);
  
  // detect mouse hover over node link
  if (mouse_x >= node_link_pos_x - node_font_height / 2 && mouse_x <= node_link_pos_x + node_font_height / 2 && mouse_y >= detect_y1 && mouse_y <= detect_y2) {
    hovered_object = HOVER_NODE_LINK;
  }
  
  // underline current position
  line(infozone_width, line_pos_y, wheel_axis_x - wheel_anchor_radius - anchor_name_distance, line_pos_y);
 
  popMatrix();
}

void drawVersion() {
  int version_x = applet_width - 5;
  int version_y = applet_height - 5;
  
  textFont(version_font);
  textAlign(RIGHT,BOTTOM);
  fill(version_font_color);
  text(version,version_x,version_y);
}

// API function for dynamic resizing
void resizeSketch(int sketch_width, int sketch_height)
{
  applet_width = sketch_width;
  applet_height = sketch_height;

  wheel_diameter = min(sketch_width-infozone_width, sketch_height);
  
  curvature = curvature_ratio * wheel_diameter;
  
  size(applet_width, applet_height);
  
  calcGraphDimensions();
}
/*
  Project:     Connection Wheel
  Name:        conwheel_animation.pde
  Purpose:     Displays connection networks on a wheel. Animation of the wheel.
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik 
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2014-10-06
  Modified:    2016-07-19  improved wheel acceleration / deceleration
      
  Comment:     -
  
  Uses:        Modules: conwheel.pde, conwheel_events.pde, 
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

class Wheel {
  int start;
  int target;
  float direction;
  float segment_distance;  // total distance to be traveled in animation
  float travel_angle;
  float velocity_full;
  float acceleration_rad;
  float acceleration_effective;
  int steps_half;
  int steps_continuous = 10;
  

  Wheel() {
    start = 0;
    target = 0;
    direction = 0;
    segment_distance = 0.0;
    velocity_full = 0.0;                        // actual velocity
    acceleration_rad = radians(acceleration);   // acceleration
  }
  
  /*
    There are two animation scenarios:
    distance is below threshold: continuous movement until target is reached
    distance is at or above threshold: acceleration until maximum velocity, constant movement, decelaration
  */
  void start_animation(int start_value, int target_value) {
    float continuous_threshold = 2 / 360 * TWO_PI;
    
    animation_step = 0;
    travel_angle = 0.0;
    
    start = start_value;
    target = target_value;
    if (target != start) {
      animation_status = STATUS_ANIMATE;
      
      velocity_full = 0.0;
      
      int target_start_diff = target - start;
      int node_count_half = node_count/2;
      if (target_start_diff < 0) {
        if (target_start_diff > -node_count_half) {
          direction = 1.0;
          segment_distance = abs(target_start_diff) * grid; 
        } else {
          direction = -1.0;
          segment_distance = (node_count + target_start_diff) * grid;
        }
      } else {
        if (target_start_diff < node_count_half) {
          direction = -1.0;
          segment_distance = target_start_diff * grid; 
        } else {
          direction = 1.0;
          segment_distance = abs(node_count - target_start_diff) * grid;
        }
      }
      
      float s = abs(segment_distance);
      
      if (s < continuous_threshold)
      {
        acceleration_status = STATUS_CONSTANTSPEED;
        velocity_full = s / steps_continuous;
      }
      else
      {
         acceleration_status = STATUS_ACCELERATE;
        // calculate the number of steps for half of the distance
        float steps_calc = ( -1.0 + sqrt(1.0 + 4.0 * s / acceleration_rad ) ) / 2.0;
        steps_half = int(steps_calc);
        float steps_half_calc = float(steps_half);
        
        // calculate effective acceleration
        acceleration_effective = s / steps_half_calc / (steps_half + 1.0 );
      }
    }
  }
  
  void animate() {
    if (acceleration_status == STATUS_CONSTANTSPEED)
    {
      // continuous movement until target is reached
      move(velocity_full);
      animation_step++;
      if (animation_step == steps_continuous)
      {
        stop_animation();
      }
    }
    else
    {
      // acceleration, deceleration
      if (animation_status == STATUS_ACCELERATE)
      {
        animation_step++;
        velocity_full = velocity_full + acceleration_effective;
        move(velocity_full);
        if (animation_step == steps_half)
        {
          animation_status = STATUS_DECELERATE;
        }
      }
      else
      {
        if (animation_status == STATUS_DECELERATE)
        {
          animation_step--;
          move(velocity_full);
          velocity_full = velocity_full - acceleration_effective;
          
          if (animation_step == 0)
          {
            stop_animation();
          }
        }
      }
    }
  }
  
  void move(float velocity)
  {
    rot_angle = rot_angle + direction * velocity;
    travel_angle = travel_angle + velocity;
    
  }
  
  void stop_animation() {
    animation_status = STATUS_STOPPED;
    current_position = target;
  }
  
  void step_anticlockwise() {
    if (animation_status == STATUS_STOPPED) {
      rot_angle = rot_angle - grid;
      current_position++;
      if (current_position > node_count-1) {
        current_position = 0;
      }
    }
  }
  
  void step_clockwise() {
    if (animation_status == STATUS_STOPPED) {
      rot_angle = rot_angle + grid;
      current_position--;
      if (current_position < 0) {
        current_position = node_count - 1;
      }
    }
  }
}
/*
  Project:     Connection Wheel
  Name:        conwheel_events.pde
  Purpose:     Displays connection networks on a wheel. Handles mouse and keyboard events.
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik 
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2014-10-12
  Modified:    -
      
  Comment:     -
  
  Uses:        Modules: conwheel.pde, conwheel_animation.pde, 
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

void keyPressed() {
  if (key == CODED && animation_status == 0) {
    switch(keyCode) {
      case LEFT:
      case UP:
        wheel.step_anticlockwise();
        break;
      case RIGHT:
      case DOWN:
        wheel.step_clockwise();
        break;
    }
  } else {
    switch(key) {
      case '+':
        bezier_radius--;
        break;
      case '-':
        bezier_radius++;
        break;
      case '=':
        bezier_radius = wheel_anchor_radius_inner - curvature;
        break;
      case '0':
        initAnimation();
        break;
      case 's':
        wheel.stop_animation();
        break;
      default:
        int keychar = int(key);
        if (keychar >= 65 && keychar <= 90) {
          keychar = keychar + 32;
        }
        if (keychar >= 97 && keychar <= 122 && animation_status == 0) {
          String keystring = String.fromCharCode(keychar);
          if (alphabet2index.get(keystring) != null) {
            int target_position = (Integer) alphabet2index.get(keystring);
            int start_position = current_position;
            wheel.start_animation(start_position,target_position);  
          }
        }
    }
  }
}

void mouseClicked() {
  if (animation_status == 0) {
    if (hovered_object > -1 && hovered_object < HOVER_HELP) {
      Node node = (Node) nodes.get(hovered_object);
      if (mouseButton == LEFT) {
        if (node.click_count == 0) {
          resetNetwork(STATUS_SELECTED);
          updateNetwork(node, STATUS_SELECTED);
        } else {
          int target_position = node.position;
          int start_position = current_position;
          wheel.start_animation(start_position,target_position);      
        }
      } else if (mouseButton == RIGHT) {
        if (node.click_count == 1) {
          resetNetwork(STATUS_SELECTED);
        }  
      } else {
      }
    } else if (hovered_object == HOVER_ITEMS_LINK) {
      if (items_base_url != null) {
        int index = (Integer) sorted2index.get(current_position);
        Node node = (Node) nodes.get(index);
        String node_name = node.name;
        String url = items_base_url + node_name;
        link(url, "_new");
      }
    } else if (hovered_object == HOVER_NODE_LINK) {
      if (node_base_url != null) {
        int index = (Integer) sorted2index.get(current_position);
        Node node = (Node) nodes.get(index);
        String node_link = node.link;
        
        String url = node_base_url + node_link;
        link(url, "_new");
      }
    }
  }
}
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
/*
  Project:     Connection Wheel
  Name:        conwheel_io.pde
  Purpose:     Displays connection networks on a circle. Loads configuration and data.
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik 
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2014-10-06
  Modified:    2016-07-20 help removed
      
  Comment:     -
  
  Uses:        Modules: conwheel.pde, conwheel_animation.pde, conwheel_events.pde, 
               conwheel_gui_classes.pde, conwheel_init.pde, conwheel_network.pde
  
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

/*

  loodConfiguration() method for loading configuration parameters from an XML file
  
  The format of the XML file must be as follows:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <configuration>
  <callback>
    <node_url>/cgi/collaborations/view?author=</node_url>
    <items_url>/cgi/search/archive/advanced?screen=Search&amp;dataset=archive&amp;_action_search=Search&amp;creators_name%2Feditors_name=</items_url>
  </callback>
  <wheel>
    <acceleration>0.05</acceleration>
    <velocity>5</velocity>
  </wheel>
  <node>
    <font name="Verdana" size="11"/>
    <anchor_diameter>4</anchor_diameter>
    <anchor_name_distance>20</anchor_name_distance>
    <colors>
      <normal>FF72AFE3</normal>
      <active>FFF00F29</active>
      <hover>FF358BD3</hover>
      <select>FFB635D3</select>
    </colors>
  </node>
  <edge>
    <line_weight>
      <normal>0.8</normal>
      <hover>1.2</hover>
      <select>1.2</select>
    </line_weight>
    <colors>
      <normal>FFE0E0E0</normal>
    </colors>
    <curvature>140.0</curvature>
  </edge>
  <version>
    <font name="Verdana" size="9" color="FFC0C0C0"/>
  </version>
</configuration>


  Description of elements:
  
  Description of <configuration> element:
    One <configuration> element must be used. It contains as sub-elements one <callback>, <wheel>, <node>, <edge>, and <help> element.
    
  Description of <callback> element:
    One <callback> element must be used. It contains the elements <node_url> and <items_url>.
  
  Description of <node_url> element:
    One element must be used. Contains base URL for node web page. String.
    
  Description of <items_url> element:
    One element must be used. Contains base URL for items web page. String.  
    
  Description of <wheel> element:
    One <wheel> element must be used. It contains the elements <acceleration> and <velocity>.
    
  Description of <acceleration> element:   
    One element must be used. Contains acceleration in degrees/step for wheel rotation. Float.
     
  Description of <velocity> element:   
    One element must be used. Contains maximum velocity in degrees/step for wheel rotation. Float.   
  
  Description of <node> element:
    One element must be used. Describes configuration for node drawing. Contains subelements <font>, <anchor_diameter>, <anchor_name_distance> and <colors>.
    
  Description of node/font element:
    One element must be used.
    
    Attributes:
      name: (String) font name used for node labels.
      size: (Float)  font size used for node labels in pt.
    
  Description of <anchor_diameter> element:
    One element must be used. Contains anchor diameter in pixels. Float.
  
  Description of <anchor_name_distance> element:
    One element must be used. Contains distance between anchor and node label in pixels. Float. 
    
  Description of node/colors element:
    One element must be used. Contains subelements <normal>, <active>, <hover>, <select>.
   
  Description of node/colors/normal element:
    One element must be used. Contains color value for the normal nodes (unhovered, inactive, unselected) in RGB mode. String. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
    
  Description of node/colors/active element:
    One element must be used. Contains color value for the active node in RGB mode. String. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
    
  Description of node/colors/hover element:
    One element must be used. Contains color value for the hovered nodes in RGB mode. String. Hexadecimal value comprising 4 bytes: alpha, red, green, blue. 
   
  Description of node/colors/select element:
    One element must be used. Contains color value for the selected nodes in RGB mode. String. Hexadecimal value comprising 4 bytes: alpha, red, green, blue 
  
  Description of <edge> element:
    One element must be used. Describes configuration for edge drawing. Contains subelements <ine_weight>, <colors>, and <curvature>.
    
  Description of <line_weight> element:
    One element must be used. Describes line weights for edges. Contains subelements <normal>, <hover>, <select>.
  
  Description of line_weight/normal element:
    One element must be used. Line weight for normal edges in pixel. Float.
    
  Description of line_weight/hover element:
    One element must be used. Line weight for hovered edges in pixel. Float.
    
  Description of line_weight/select element:
    One element must be used. Line weight for selected edges in pixel. Float.
  
  Description of edge/colors element:
    One element must be used. Describes edge colors. Contains subelement <normal>.
    
  Description of edge/colors/normal element:
    One element must be used. Contains color value for the normal (unhovered, unselected) edges in RGB mode. String. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.
   
  Description of the <curvature> element:
     One element must be used. Describes default bezier curvature for edges. Float. 
  
   Description of <version> element:
    One element must be used. Describes configuration of the version message. Contains one <font> sub-element.
    
  Description of version/font element:
    One element must be used. 
  
    Attributes:
      name:  (String) font name used for version message.
      size:  (Float)  font size used for version message in pt.
      color: (String) color used for version message in RGB mode. Hexadecimal value comprising 4 bytes: alpha, red, green, blue.

  
  XML Schema:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:element name="configuration">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="callback"/>
          <xs:element ref="wheel"/>
          <xs:element ref="node"/>
          <xs:element ref="edge"/>
          <xs:element ref="help"/>
          <xs:element ref="version"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="callback">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="node_url"/>
          <xs:element ref="items_url"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="node_url">
      <xs:complexType/>
    </xs:element>
    <xs:element name="items_url">
      <xs:complexType/>
    </xs:element>
    <xs:element name="wheel">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="acceleration"/>
          <xs:element ref="velocity"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="acceleration" type="xs:decimal"/>
    <xs:element name="velocity" type="xs:integer"/>
    <xs:element name="node">
      <xs:complexType>
        <xs:complexContent>
          <xs:extension base="font">
            <xs:sequence>
              <xs:element ref="anchor_diameter"/>
              <xs:element ref="anchor_name_distance"/>
              <xs:element ref="colors"/>
            </xs:sequence>
          </xs:extension>
        </xs:complexContent>
      </xs:complexType>
    </xs:element>
    <xs:element name="anchor_diameter" type="xs:integer"/>
    <xs:element name="anchor_name_distance" type="xs:integer"/>
    <xs:element name="edge">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="line_weight"/>
          <xs:element ref="colors"/>
          <xs:element ref="curvature"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="line_weight">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="normal"/>
          <xs:element ref="hover"/>
          <xs:element ref="select"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="curvature" type="xs:decimal"/>
    <xs:element name="help">
      <xs:complexType>
        <xs:complexContent>
          <xs:extension base="font">
            <xs:sequence>
              <xs:element ref="box"/>
              <xs:element ref="description"/>
            </xs:sequence>
          </xs:extension>
        </xs:complexContent>
      </xs:complexType>
    </xs:element>
    <xs:element name="box">
      <xs:complexType>
        <xs:attribute name="background-color" use="required" type="xs:NCName"/>
        <xs:attribute name="border-color" use="required" type="xs:NCName"/>
        <xs:attribute name="border-weight" use="required" type="xs:decimal"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="description">
      <xs:complexType>
        <xs:sequence>
          <xs:element maxOccurs="unbounded" ref="item"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="item">
      <xs:complexType>
        <xs:attribute name="lang" use="required" type="xs:NCName"/>
        <xs:attribute name="text" use="required"/>
        <xs:attribute name="title" use="required"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="version" type="font"/>
    <xs:complexType name="font">
      <xs:sequence>
        <xs:element ref="font"/>
      </xs:sequence>
    </xs:complexType>
    <xs:element name="font">
      <xs:complexType>
        <xs:attribute name="color" type="xs:NCName"/>
        <xs:attribute name="name" use="required" type="xs:NCName"/>
        <xs:attribute name="size" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="colors">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="normal"/>
          <xs:sequence minOccurs="0">
            <xs:element ref="active"/>
            <xs:element ref="hover"/>
            <xs:element ref="select"/>
          </xs:sequence>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="active" type="xs:NCName"/>
    <xs:element name="normal" type="xs:NMTOKEN"/>
    <xs:element name="hover" type="xs:NMTOKEN"/>
    <xs:element name="select" type="xs:NMTOKEN"/>
  </xs:schema>

*/


void loadConfiguration(String fname) { 
  XML xml_configuration = loadXML(fname);
  
  // callback URL configuration
  XML xml_callback = xml_configuration.getChild("callback");
  XML xml_node_url = xml_callback.getChild("node_url");
  node_base_url = xml_node_url.getContent();
  XML xml_items_url = xml_callback.getChild("items_url");
  items_base_url = xml_items_url.getContent();
  
  // wheel configuration
  XML xml_wheel = xml_configuration.getChild("wheel");
  XML xml_acceleration = xml_wheel.getChild("acceleration");
  acceleration = float(xml_acceleration.getContent());
  XML xml_velocity = xml_wheel.getChild("velocity");
  velocity = float(xml_velocity.getContent());
  
  // node configuration
  XML xml_node = xml_configuration.getChild("node");
  XML xml_node_font = xml_node.getChild("font");
  node_font_name = xml_node_font.getString("name");
  node_font_size = xml_node_font.getFloat("size");
  XML xml_anchor_diameter = xml_node.getChild("anchor_diameter");
  anchor_diameter = float(xml_anchor_diameter.getContent());
  XML xml_anchor_name_distance = xml_node.getChild("anchor_name_distance");
  anchor_name_distance = float(xml_anchor_name_distance.getContent());
  XML xml_node_color_normal = xml_node.getChild("colors/normal");
  String node_color_normal_string = xml_node_color_normal.getContent();
  node_color_normal = unhex(node_color_normal_string);
  XML xml_node_color_active = xml_node.getChild("colors/active");
  String node_color_active_string = xml_node_color_active.getContent();
  node_color_active = unhex(node_color_active_string);
  XML xml_node_color_hover = xml_node.getChild("colors/hover");
  String node_color_hover_string = xml_node_color_hover.getContent();
  node_color_hover = unhex(node_color_hover_string);
  XML xml_node_color_selected = xml_node.getChild("colors/select");
  String node_color_selected_string = xml_node_color_selected.getContent();
  node_color_selected = unhex(node_color_selected_string);
 
  
  // edge configuration
  XML xml_edge = xml_configuration.getChild("edge");
  XML xml_edge_line_weight_normal = xml_edge.getChild("line_weight/normal");
  edge_weight_normal = float(xml_edge_line_weight_normal.getContent());
  XML xml_edge_line_weight_hover = xml_edge.getChild("line_weight/hover");
  edge_weight_hover = float(xml_edge_line_weight_hover.getContent());
  XML xml_edge_line_weight_selected = xml_edge.getChild("line_weight/select");
  edge_weight_selected = float(xml_edge_line_weight_selected.getContent());
  XML xml_edge_color_normal = xml_edge.getChild("colors/normal");
  String edge_color_normal_string = xml_edge_color_normal.getContent();
  edge_color = unhex(edge_color_normal_string);
  XML xml_edge_curvature = xml_edge.getChild("curvature");
  curvature = float(xml_edge_curvature.getContent());
  
  // version HUD configuration
  XML xml_version_font = xml_configuration.getChild("version/font");
  version_font_name = xml_version_font.getString("name");
  version_font_size = xml_version_font.getFloat("size");
  String version_font_color_string = xml_version_font.getString("color");
  version_font_color = unhex(version_font_color_string);
}

/*
  loadData() method for loading all nodes and edges from an XML file. 
  
  Nodes and edges are being deduplicated.

  The format of the XML file must be as follows:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <graph>
    <nodes>
      <n id="1574" t="Roos, C" c="5" a="Roos, C"/>
      <n id="130" t="Fausser, J L" c="1" a="Fausser, J L"/>
      .
      .
      .
      <n id="1340" t="Zimmermann, E" c="25" a="Zimmermann, E"/>
    </nodes>
    <edges>
      <e id="52777" f="1950" t="1754" r="91"/>
      <e id="52876" f="1340" t="1950" r="91"/>
      .
      .
      <e id="52760" f="619" t="1074" r="91"/>
    </edges>
    <active_node r="201"/>
  </graph>
  
  Description of <node ...> element:
    For each node in the graph, one <node ...> element must be used.
    
    Attributes:
      id: (String) Unique identification for the node.
      t:  (String) Node label
      c:  (Integer) number of associated items, e.g. number of publications of an author
      a:  (String) URL part used to create an URL for linking to another graph.
  
  Description of the <edge ...> element:
    For each edge in the graph, one <edge ...> element must be used.
    
    Attributes:
      id: (String) Unique id for the edge
      f:  (String) Id of the start node  (from node)
      t:  (String) Id of the end node  (to node)
      r:  (String) Id of the item the edge belongs to
      
  Description of the <active_node ...> element:
    Exactly one element must be used. It is used to highlight the active node with "active" color.
    
    Attributes:
      r: (integer) Unique identification number for the node, must be one of the node ids in the node list.
      
  
  XML Schema:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:element name="graph">
      <xs:complexType>
        <xs:sequence>
          <xs:element ref="nodes"/>
          <xs:element ref="edges"/>
          <xs:element ref="active_node"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="nodes">
      <xs:complexType>
        <xs:sequence>
          <xs:element maxOccurs="unbounded" ref="n"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="n">
      <xs:complexType>
        <xs:attribute name="a" use="required"/>
        <xs:attribute name="c" use="required" type="xs:integer"/>
        <xs:attribute name="id" use="required" type="xs:integer"/>
        <xs:attribute name="t" use="required"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="edges">
      <xs:complexType>
        <xs:sequence>
          <xs:element maxOccurs="unbounded" ref="e"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="e">
      <xs:complexType>
        <xs:attribute name="f" use="required" type="xs:integer"/>
        <xs:attribute name="id" use="required" type="xs:integer"/>
        <xs:attribute name="r" use="required" type="xs:integer"/>
        <xs:attribute name="t" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
    <xs:element name="active_node">
      <xs:complexType>
        <xs:attribute name="r" use="required" type="xs:integer"/>
      </xs:complexType>
    </xs:element>
  </xs:schema>
  
*/

void loadData(String fname) {
  xml_data = loadXML(fname);
  loadNodes();
  loadEdges();
  loadInitialData();
}

void loadNodes() {
  int name_length_max = 0;
  
  XML [] xml_nodes = xml_data.getChildren("nodes/n");
  int node_count_temp = xml_nodes.length;
  node_count = 0;
  for (int i = 0; i < node_count_temp; i++) {
    XML xml_node = xml_nodes[i];
    String id = xml_node.getString("id");
    String name = xml_node.getString("t");
    String link = xml_node.getString("a");
    int items_count = xml_node.getInt("c");
    boolean node_added = addNode(id,name,link,items_count);
    
    if (node_added) {
      node_count++;
      // find longest name string in order to calculate the size of the wheel later
      int name_length = name.length();
      if (name_length > name_length_max) {
        name_length_max = name_length;
        name_length_max_pointer = id;
      }
    }
  }
}

boolean addNode(String id, String name, String link, int items_count) {
  // deduplicate nodes
  boolean duplicate = false;
  boolean added = false;
  
  for (int j = 0; j < node_count; j++) {
    Node node = (Node) nodes.get(j);
    if (node.id.equals(id)) {
      duplicate = true;
    }
  }
  if (duplicate == false) {
    node2index.put(id,node_count);
    node_name2index.put(name.toLowerCase(),node_count);
    // first add unsorted
    nodes.add(new Node(id,node_count,items_count,name,link));
    added = true;
  }
  return added;
}

void loadEdges() {
  edge_count = 0;
  edgegroup_count = 0;
  
  XML [] xml_edges = xml_data.getChildren("edges/e");
  int edge_count_temp = xml_edges.length;
  edge_count = 0;
  for (int i = 0; i < edge_count_temp; i++) {      
    XML xml_edge = xml_edges[i];
    String id = xml_edge.getString("id");
    String node_from = xml_edge.getString("f");
    String node_to = xml_edge.getString("t");
    String ref = xml_edge.getString("r");

    boolean added = addEdge(id, node_from, node_to, ref);
    if (added) {
      edge_count++;
    }
  }
}

boolean addEdge(String id, String node_from, String node_to, String ref) {
  // check whether the two nodes exist, otherwise discard edge
  boolean added = false;
  if (node2index.get(node_from) != null && node2index.get(node_to) != null) {
    int node_index_from = (Integer) node2index.get(node_from);
    int node_index_to = (Integer) node2index.get(node_to);

    edges.add(new Edge(id, node_from, node_to, ref, node_index_from, node_index_to));
    
    // add edge to edgegroup belonging to reference
    
    if (edgegroup2index.get(ref) == null) {
      // create new edge group 
      edgegroups.add(new EdgeGroup(ref));
      edgegroup2index.put(ref,edgegroup_count);
      EdgeGroup edgegroup = (EdgeGroup) edgegroups.get(edgegroup_count);
      edgegroup.addEdge(edge_count);
      edgegroup_count++;
    } else {
      int edgegroup_index = (Integer) edgegroup2index.get(ref);
      EdgeGroup edgegroup = (EdgeGroup) edgegroups.get(edgegroup_index);
      edgegroup.addEdge(edge_count);
    }
    
    // add edge reference to source and target node
    Node from = (Node) nodes.get(node_index_from);
    Node to = (Node) nodes.get(node_index_to);
    from.addEdgeGroupRef(ref);
    to.addEdgeGroupRef(ref);
    
    added = true;
  }
  return added;
}


void loadInitialData() {
  XML xml_active_node = xml_data.getChild("active_node");
  active_node = xml_active_node.getString("r");
  if (node2index.get(active_node) != null) {
    int active_node_index = (Integer) node2index.get(active_node);
    Node node = (Node) nodes.get(active_node_index);
    node.setActiveStatus();
  }
}


void sortData() {
  node_names = new String[node_count];
  for (int i = 0; i < node_count; i++) {
    Node node = (Node) nodes.get(i);
    node_names[i] = node.name.toLowerCase();
  }
  node_names = sort(node_names);
  
  for (int i = 0; i < node_count; i++) {
    int index = (Integer) node_name2index.get(node_names[i]);
    Node node = (Node) nodes.get(index);
    node.updatePosition(i);
    sorted2index.put(i,index);
  }
  
  String char_comp = str(' ');
  for (int i = 0; i < node_count; i++) {
    int index = (Integer) sorted2index.get(i);
    Node node = (Node) nodes.get(index);
    String first = str(node.name.toLowerCase().charAt(0));
    if (first != char_comp) {
      char_comp = first;
      int position = node.position;
      alphabet2index.put(first,position);
    }
  }  
}
/*
  Project:     Connection Wheel
  Name:        conwheel_network.pde
  Purpose:     Displays connection networks on a wheel. Updates hovered/selected networks.
  Version:     1.0
              
  Author:      Dr. Martin Brändle
               martin.braendle@id.uzh.ch
               
  Address:     University of Zurich
               Zentrale Informatik 
               Stampfenbachstr. 73
               8006 Zurich
               Switzerland
  
  Date:        2014-10-06
  Modified:    -
      
  Comment:     -
  
  Uses:        Modules: conwheel.pde, conwheel_animation.pde, conwheel_events.pde, 
               conwheel_gui_classes.pde, conwheel_init.pde, conwheel_io.pde
  
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

void updateNetwork(Node start_node, int event_status) {
  if (start_node.status != STATUS_SELECTED && start_node.status != STATUS_ACTIVE) {
    int node_edgegroup_refs_count = start_node.edgegroup_refs_count;
    for (int i = 0; i < node_edgegroup_refs_count; i++) {
      String node_edgegroup_ref = (String) start_node.edgegroup_refs.get(i);
      int edge_group_index = (Integer) edgegroup2index.get(node_edgegroup_ref);
      EdgeGroup edgegroup = (EdgeGroup) edgegroups.get(edge_group_index);
      
      if (event_status == STATUS_HOVERED) {
        edgegroups_hovered.add(node_edgegroup_ref);
      }
      
      if (event_status == STATUS_SELECTED) {
        edgegroups_selected.add(node_edgegroup_ref);
      }
      
      for (int j = 0; j < edgegroup.edge_indexes.size(); j++) {
        int edge_index = (Integer) edgegroup.edge_indexes.get(j);
        Edge edge = (Edge) edges.get(edge_index);
        int from_index = edge.from_index;
        int to_index = edge.to_index;
        Node node_from = (Node) nodes.get(from_index);
        Node node_to = (Node) nodes.get(to_index);
        
        edge.updateStatus(event_status);
        node_from.updateStatus(event_status);
        node_to.updateStatus(event_status);
      
        if (event_status == STATUS_SELECTED) {
          node_from.updateClickCount();
          node_to.updateClickCount();
        }
      }
    }
  }
}


void resetNetwork(int event_status) {
  if (event_status == STATUS_HOVERED) {
    for (int i = 0; i < edgegroups_hovered.size(); i++) {
      String edgegroup_ref = (String) edgegroups_hovered.get(i);
      int edge_group_index = (Integer) edgegroup2index.get(edgegroup_ref);
      EdgeGroup edgegroup = (EdgeGroup) edgegroups.get(edge_group_index);
      
      for (int j = 0; j < edgegroup.edge_indexes.size(); j++) {
        int edge_index = (Integer) edgegroup.edge_indexes.get(j);
        Edge edge = (Edge) edges.get(edge_index);
        int from_index = edge.from_index;
        int to_index = edge.to_index;
        Node node_from = (Node) nodes.get(from_index);
        Node node_to = (Node) nodes.get(to_index);
        
        if (node_from.status != STATUS_SELECTED && node_to.status != STATUS_SELECTED) {
          node_from.resetStatus();
          node_to.resetStatus();
          edge.updateStatus(STATUS_NORMAL);
        }
      }
    }
    
    // re-enable selected status for those nodes that were clicked
    for (int i = 0; i < node_count; i++) {
      Node node = (Node) nodes.get(i);
      if (node.click_count == 1) {
        node.updateStatus(STATUS_SELECTED);
      }
    }
    
    edgegroups_hovered.clear();
  }
  
  if (event_status == STATUS_SELECTED) {
    for (int i = 0; i < edgegroups_selected.size(); i++) {
      String edgegroup_ref = (String) edgegroups_selected.get(i);
      int edge_group_index = (Integer) edgegroup2index.get(edgegroup_ref);
      EdgeGroup edgegroup = (EdgeGroup) edgegroups.get(edge_group_index);
      
      for (int j = 0; j < edgegroup.edge_indexes.size(); j++) {
        int edge_index = (Integer) edgegroup.edge_indexes.get(j);
        Edge edge = (Edge) edges.get(edge_index);
        int from_index = edge.from_index;
        int to_index = edge.to_index;
        Node node_from = (Node) nodes.get(from_index);
        Node node_to = (Node) nodes.get(to_index);
        
        edge.updateStatus(STATUS_NORMAL);
        node_from.resetClickCount();
        node_to.resetClickCount();
        node_from.resetStatus();
        node_to.resetStatus();
      }
    }
    edgegroups_selected.clear();
  }
}
