/*
	GENERAL TOOLS
*/

function merge(arrays){
  return [].concat.apply([], arrays)
}

function objectToName(obj){
  return obj.name
}


/*
	TREE TOOLS
*/

function saveParentInsideChild(parent){
  return function(child) {
    child.parent_for_level = parent;
    return child;
  }
}

function getChildren(parent){
  if (parent != null && parent.children && parent.children.length > 0)
    return parent.children.map(saveParentInsideChild(parent))
  else
    return []
}

function getAllChildren(tree){
  var result = [];
  var children_raw = [];
  var children = getChildren(tree);
  result.push(children);
  
  while(children.length > 0) {
    children_raw = children.map(getChildren);
    children = merge(children_raw);
    if(children.length > 0) result.push(children);
  }

  return merge(result);
}

/*
	SEARCH TREE TOOLS
*/

function check(child_for_search, child_to_check){
    var childrenNames = getAllChildren(child_for_search).map(objectToName);
    var repeated = childrenNames.indexOf(child_to_check.name) != -1;
    if(repeated) {
      if(child_to_check.repeated == null)
        child_to_check.repeated = [];
        child_to_check.repeated.push("'" + child_for_search.name + "'");
    }
}

function calculateRepeatingIn(node){
    var children = getChildren(node);
    var n = children.length;

    for(var i = 0; i < n; i++) {
      child1 = children[i];
      for(var j = 0; j < n; j++){
        if(i != j){
          child2 = children[j];
          //console.log("check for " + child2.name + " in " + child1.name);
          check(child1, child2);
        }
      }
    }

    children.forEach(calculateRepeatingIn);
}