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