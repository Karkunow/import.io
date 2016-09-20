var margin = {top: 20, right: 10, bottom: 30, left: 250},
    width = 6000;//2860 - margin.right - margin.left,
    height = window.innerHeight - margin.top - margin.bottom; 

var real_width = width + margin.right + margin.left;
var real_height = height + margin.top + margin.bottom; 
var i = 0,
    duration = 750,
    root;

var tree = d3.layout.tree()
    .size([height, width]);

var diagonal = d3.svg.diagonal()
    .projection(function(d) { return [d.y, d.x]; });

var svg = d3.select("#mscreen").append("svg")
    //.attr("width", width + margin.right + margin.left)
    //.attr("height", height + margin.top + margin.bottom)
   .attr("preserveAspectRatio", "xMinYMin meet")
   .attr("viewBox", "0 0 "+ real_width + " " + real_height)
   .classed("svg-content-responsive", true)
   .append("g")
   .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.json("data/force.csv", function(error, flare) {
  if (error) throw error;

  root = flare;
  root.x0 = height / 2;
  root.y0 = 0;

  calculateRepeatingIn(flare);

  root.children.forEach(collapse);
  update(root);
});