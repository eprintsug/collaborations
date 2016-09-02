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