//
// function to determine the canvas size for the author connection wheel
// requires JQuery
//

function getConWheelCanvasSize() {
  var h, b;
  var bw = jQuery( '#cw_body' ).width();
  var bh = jQuery( '#cw_body' ).height();
  bh = Math.min(720,bh);
  bh = Math.max(bh,320);
  if (bw - 80 > bh)
  {
    h = bh;
    w = h + 80;
  }
  else
  {
    w = bw;
    h = w - 80;
  }
  resizeCW( w,h );
  jQuery( '#ConWheel' ).width(w);
  jQuery( '#ConWheel' ).height(h);
  jQuery( '#content_cw' ).width(w);
}


//
// function to resize the Processing sketch (calls method resizeSketch in ConWheel.pde)
//

var pjs;
    
function resizeCW(w,h) {
  if (!pjs) {
    pjs = Processing.getInstanceById('ConWheel');
  }
  pjs.noLoop();
  pjs.resizeSketch(w,h);
  pjs.loop();
};

