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