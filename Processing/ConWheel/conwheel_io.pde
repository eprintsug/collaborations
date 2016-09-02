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