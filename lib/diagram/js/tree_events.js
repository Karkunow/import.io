function update(source) {

  // Compute the new tree layout.
  var nodes = tree.nodes(root).reverse(),
      links = tree.links(nodes);

  // Normalize for fixed-depth.
  nodes.forEach(function(d) { d.y = d.depth * 500; });

  // Update the nodes…
  var node = svg.selectAll("g.node")
      .data(nodes, function(d) { return d.id || (d.id = ++i); });

  // Enter any new nodes at the parent's previous position.
  var nodeEnter = node.enter().append("g")
      .attr("class", "node")
      .attr("transform", function(d) { return "translate(" + source.y0 + "," + source.x0 + ")"; })
      .on("click", onclick(update));

  nodeEnter.append("circle")
      .attr("r", 1e-6)
      .style("fill", update_color)
      .on('mouseover', mouseover(d3))
      .on('mouseout', mouseout(d3));

  var radius = 15.0;
  nodeEnter.append("text")
      .attr("x", -radius)
      .attr("dy", "1.5em")
      .attr("text-anchor", "end")
      .text(function(d) { return d.name; })
      .style("fill-opacity", 1e-6);

  // Transition nodes to their new position.
  var nodeUpdate = node.transition()
      .duration(duration)
      .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; });

  nodeUpdate.select("circle")
      .attr("r", radius)
      .style("fill", update_color);

  nodeUpdate.select("text")
      .style("fill-opacity", 1);

  // Transition exiting nodes to the parent's new position.
  var nodeExit = node.exit().transition()
      .duration(duration)
      .attr("transform", function(d) { return "translate(" + source.y + "," + source.x + ")"; })
      .remove();

  nodeExit.select("circle")
      .attr("r", 1e-6);

  nodeExit.select("text")
      .style("fill-opacity", 1e-6);

  // Update the links…
  var link = svg.selectAll("path.link")
      .data(links, function(d) { return d.target.id; });

  // Enter any new links at the parent's previous position.
  link.enter().insert("path", "g")
      .attr("class", "link")
      .attr("d", function(d) {
        var o = {x: source.x0, y: source.y0};
        return diagonal({source: o, target: o});
      });

  // Transition links to their new position.
  link.transition()
      .duration(duration)
      .attr("d", diagonal);

  // Transition exiting nodes to the parent's new position.
  link.exit().transition()
      .duration(duration)
      .attr("d", function(d) {
        var o = {x: source.x, y: source.y};
        return diagonal({source: o, target: o});
      })
      .remove();

  // Stash the old positions for transition.
  nodes.forEach(function(d) {
    d.x0 = d.x;
    d.y0 = d.y;
  });
}

function onclick(updateFn) {
  return function (d) {
    if (d.children) {
      d._children = d.children;
      d.children = null;
    } else {
      d.children = d._children;
      d._children = null;
    }
    updateFn(d);
  }
}

function delete_mouseover_popup(d3){
  return function (d) {
    console.log("mouseout");
    if(d.repeated && !d3.select("#mouseover").empty()){
      d3.select("#mouseover").remove();
    }
  }
}

function mouseover(d3) {
  return function (d) {
    console.log("MOUSEOVER");
    if(d.repeated && d3.select("#mouseover").empty()){
      console.log("MOUSEOVER INSIDE");
      var point_to_go = this.parentNode.getAttribute("transform");
      point_to_go = point_to_go.slice(10);
      var len = point_to_go.length;
      point_to_go = point_to_go.substring(0, len - 1).split(",").map(parseFloat);
      point_to_go[0] += 230;
      point_to_go[1] += -50;

      d3.select("#mscreen")
      .append("div")
      .attr("style", "margin-left: " + point_to_go[0] + "px; margin-top: " + point_to_go[1] + "px;")
      .attr("class", "popup")
      .attr("id", "mouseover")
      .append("p")
      .append("center")
      .text("This module is repeated in " + d.repeated.join(", "))
    }
  }
}

function mouseout(d3) {
  return delete_mouseover_popup(d3);
}

function update_color(d) {
  var default_color = d._children ? "lightsteelblue" : "#fff";
  var children_count = 0;

  if(d._children)
    children_count = d._children.length

  if(d.children)
    children_count = d.children.length;

  if(d.repeated && children_count  > 15) return "orange";
  if(d.repeated && children_count  == 0) return "#fbffb5";
  if(d.repeated) return "yellow";
  return children_count  > 15 ? "#ff0000" : default_color;
};

function collapse(d) {
  if (d != null && d.children && d.children.length > 0) {
    d._children = d.children;
    d._children.forEach(collapse);
    d.children = null;
  }
}