#Collaborations
##Visualisation of author collaborations

The collaborations package analyses the author collaborations in an EPrints repository 
and visualises them on an interactive wheel. The author collaboration network graphs are 
processed with a script and saved as XML files. The graphs are visualised using 
ProcessingJS. The network visualisation can be classified as radial 
convergence according to the typology used by Manuel Lima (Visual Complexity,
Mapping Patterns of Information, Princeton, NY, 2011, ISBN 978-1-56898-936-5). 

The package consists of 
- a script and plugin to generate the graph files
- a cgi script and screen plugin for the visualisation
- the ProcessingJS program (including the Processing source files) to visualise the
  collaboration XML graph files
- some JavaScript helper code
- phrase files in English and German

For a demo, see e.g. http://www.zora.uzh.ch/cgi/collaborations/view?author=Gloor%20C


##Requirements

JQuery is required for scaling the visualisation canvas.


##General setup

The setup procedure consists of the following steps

- Installation of the required files
- Configuration of the views.pl file
- Configuration of the look of the visualisation
- Initial generation of coauthor data
- Linking the coauthor_data directory
- Initial test
- Full generation of coauthor data
- Running updates


##Installation

Copy the content of the bin and cfg directories to the respective 
{eprints_root}/archives/{yourarchive}/bin and {eprints_root}/archives/{yourarchive}/cfg 
directories.

Copy the content of the cgi directory to the  {eprints_root}/cgi directory.


##Configuration

###Edit the z_collaborations.pl file

In your cfg.d/z_collaborations.pl file, you need to adapt the 

```perl
$c->{collaboration_fields} = [
  'creators_abbrv',
  'editors_abbrv'
];
```

part to the field names that are used in your repository.


###Edit your views.pl file

In your cfg.d/views.pl file, find the configuration that is used to for generation and 
display of the Browse Authors view.

Add a `render_menu => "render_view_menu_authors",` line to the menus configuration of the
respective view.

E.g. for the view "authorsnew":

```perl
        {
                id => "authorsnew",
                allow_null => 1,
                menus => [
                       {
                          fields => [ "creators_abbrv", "editors_abbrv" ],
                          mode => "sections",
                          grouping_function => "EPrints::Update::Views::group_by_first_character",
                          group_sorting_function => "EPrints::Update::Views::default_sort",
                          group_range_function => "EPrints::Update::Views::cluster_ranges_40",
                          open_first_section => 1,
                          new_column_at => [ 0 ],
                          render_menu => "render_view_menu_authors",
                       },
                ],
                order => "-date/title",
                variations => [ "date;truncate=4,reverse",
                                "type",
                                "refereed_set",
                                "status",
                ],
                # cache menu pages for 4 days
                max_menu_age => 4*24*60*60,
                max_items => 1000,
        },

```

###Edit the look of your visualisation

You can configure the look of your visualisation (color, fonts, line widths) in 
archives/{archive}/cfg/static/coauthors/configuration.xml:

```XML
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
```

Some explanations:

The `<items_url>` element contains the callback URL fragment for an advanced search of the 
author's eprints of when a user clicks on the number of items link in a graph.
This URL must be adapted to the author name field you are using in your repository: 
Replace `creators_name%2Feditors_name` with the corresponding contributor field name(s).

The node size (more precisely, the area of the node) is proportional to the number of 
items an author has published. The `<anchor_diameter>` element defines a minimum diameter
in pixels for authors with only 1 publication.

The `<anchor_name_distance>` element defines the distance between the author label and the
node.

The `<acceleration>` and `<velocity>` elements configure the speed of the wheel rotation in
degrees per rotation step. You may experiment with these values.

All color values are 4-Byte hexadecimal values in the order ARGB (alpha, red, green, 
blue channel). A value of FF for the alpha channel means that the color is opaque, 
smaller values increase transparency.

The `<curvature>` element sets the curvature of the Bezier curves that connect the nodes 
in pixels. This value is relative to an initial graph size of 800 px x 800 px - the 
ConWheel Processing code calculates from this a relative curvature that is used when the 
graph is resized in a responsive GUI.


###Restart the web server

After you have edited the configuration files, restart the web server.


##Initial generation of coauthor data

To initialize and test your setup, create coauthor graphs for one (1) eprint:

```
sudo -u apache {eprints_root}/archives/{repo}/bin/generate_collaborations {repo} 1 --save 
```

The generate_collaborations script does the following:
- It creates the directory `{eprints_root}/archives/{archive}/html/coauthor_data`
- It saves all unique author names in the file author_list.xml. You can inspect this file
  for later reference and to obtain an indication of the author count in your repository 
- For eprint 1 and its authors, it creates all the collaboration graph files.

(as a side note: the format of the collaboration graph files is described in  
https://github.com/eprintsug/collaborations/blob/master/Processing/ConWheel/conwheel_io.pde
https://github.com/eprintsug/collaborations/tree/master/Processing/ConWheel/xml_schemas )


###Linking the coauthor_data directory

The coauthor_data directory must be linked to all your language-specific HTML collaboration
directories so that the data can be accessed by the Processing code. Do the following:

```
cd {eprints_root}/archives/{repo}/html/{language}/collaborations/
ln -s {eprints_root}/archives/{repo}/html/coautor_data data
```

Repeat these commands for every language, e.g. en, de, and so on.

###Initial test

Inspect the `archives/{archive}/html/coauthor_data` directory and choose one of the author
names saved there.

Create a URL `http://your_repository_domain/cgi/collaborations/view?author={author_name}`
Use %20 to encode a white space.
As an example: http://www.zora.uzh.ch/cgi/collaborations/view?author=Gloor%20C

If the graph is displayed, you are nearly set. Click twice on another author in the 
graph to rotate it into its base position. Click on the node link left to name to check
whether the graph of the chosen author is loaded as well. Click on the items count 
left to the name to check whether the advanced search of the publications does work (see 
Edit the look of your visualisation).


##Generating the author collaborations: The generate_collaborations script

Now a full run to generate the author collaborations must be carried out:

```
sudo -u apache {eprints_root}/archives/{repo}/bin/generate_collaborations {repo}
```

Depending on the number of eprints and author names, this may take a long time. Assume 
a computation time of about 12 hours for about 100'000 authors.
Be also prepared that your file system has reserved enough space for the graph files. 
The required space grows about quadratically with author count due to the edges connecting
the authors. About 4 GB are required for 100'000 authors.


`sudo -u apache {eprints_root}/archives/{repo}/bin/generate_collaborations --help` lists all options.


##Generating the author view

Recreate the author browse view using

```
sudo -u apache {eprints_root}/bin/generate_views {repo} --view {authorview} --generate menus
```

Anyway, we assume that you have a cron job that carries out this command regularly.

The author views should contain beside each author name a "Coauthors" link that links to 
the respective collaboration graph.


##Running updates

There are two options in for running updates with the generate_collaborations script:

`--update`: Generates collaboration graph files for a daily segment of eprints, so that
within one month all eprints are processed once, including the newly added eprints.
`--new`: Generates collaboration graph files only for eprints that were
added to the live archive yesterday.

For a small repository with a few 1000 eprints, we recommend to use the `--update` option. 
This keeps the whole collaboration graph (i.e. the graph of all combined author 
collaborations) up-to-date.

For a large repository with several 10000 eprints, we recommend to use `--new` in a nightly
cronjob, which reduces processing time to about 10-15 minutes, and to carry out a 
a complete run every 6-12 months.

`--new` has the following effect: 
- For new authors, a collaboration graph file will be created. The item counts of all the 
authors in these graph files are correct.
- For existing authors that are found in the new eprints, the collaboration graph file will
be updated. The item counts of all the authors in these graph files are correct.
- In the graph files of the coauthors of the set of existing authors above, the item counts
of the existing authors in the set before are not updated, since that would include a 
traversal across the whole collaboration graph. Hence, the item counts are only a lower
approximation of the correct item counts (usually differing by 1).
In other words: Only a next-neighbor search will carried out in the collaboration graphs 
of the authors in the new eprints.


##Editing the Processing code (for developers)

The ConWheel.pde file being used in the EPrints repo can be found in cfg/static/coauthors 
and can be used as is.

If you need or want to modify the visualisation itself, the individual functional modules 
of the Processing code are available in Processing/ConWheel. From these, you can create
the combined ConWheel.pde with the help of the Processing Development Environment 
(aka "Processing"). 

Processing can be obtained from

https://www.processing.org/download/

After you have installed Processing, the JavaScript mode must be installed as
well. Start Processing, and create a new sketch. In the top right corner of the 
Processing window, there is a dropdown menu called "Java". Choose "Add mode ...", and 
select "JavaScript Mode" from the list, then choose "Install".
 
Copy the folder "ConWheel" to your sketchbook location (see Processing Preferences, where
you can configure the sketchbook location).

Switch to JavaScript mode and edit the modules.

To create ConWheel.pde, use menu File > Export. A directory web-export is created in the
ConWheel folder that contains ConWheel.pde and all other necessary files. 
The visualisation can be tested by loading index.html in a Web browser.  





