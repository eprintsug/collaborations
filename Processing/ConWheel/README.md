#ConWheel - Processing(JS) code for visualisation of graphs on a wheel

This is the standalone Processing(JS) code for ConWheel (Connection Wheel).

ConWheel reads a network graph and displays it on an interactive wheel.
The visualisation can be classified as radial convergence according to the typology used 
by Manuel Lima (Visual Complexity, Mapping Patterns of Information, Princeton, NY, 2011, 
ISBN 978-1-56898-936-5). 

Since the nodes are ordered alphabetically on the wheel, it is well-suited to visualize
author collaborations, but other applications are possible as well.

Graph data, defined as a set of nodes and edges, and configuration parameters for the 
look and feel of the graph are read from two XML files, e.g. data.xml and 
configuration.xml. 
Examples files can be found in the data directory.
The detailed format and description of the files is described in module conwheel_io.pde .
Their XML schemas are available in the directory xml_schemas.


Commands to control the wheel:

Mouse:

left click: 1st click select node, 2nd click rotate node to active position

right click: unselect node

click on publication count: gets publications of the author on the active position

click on node beneath publication count: goes to collaboration visualisation of the author on the active position

Keys:

0 : reset wheel rotatation

Cursor →↓ : rotate anti-clockwise

Cursor ←↑ : rotate clockwise

a-z : jump to letter

+ : increase curvature

- : decrease curvature

= : default curvature
