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