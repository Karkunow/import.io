/*
	GENERAL TOOLS
*/

function merge(arrays){
  var acc = [];
  for(var i = 0; i < arrays.length; i++)
    acc = acc.concat(arrays[i]);
  return acc;
}

function objectToName(obj){
  return obj.name
}


/*
	TREE TOOLS
*/

function getChildren(parent){
  if (parent != null && parent.children && parent.children.length > 0)
    return parent.children;
  else
    return [];
}

function getAllChildren(tree){
  var result = [];
  var children_raw = [];
  var children = [tree];
  
  while(children.length > 0) {
    children_raw = children.map(getChildren);
    children = merge(children_raw);
    if(children.length > 0)
      result = result.concat(children);
  }

  return result;
}