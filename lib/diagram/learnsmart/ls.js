
function ReadFlowFiles(jsonTree, folderObj){	    
    var filesCollection = new Enumerator(folderObj.Files);  
    var fileObj; 
    
    var folderName = folderObj.Name;
	jsonTree.name = folderName;
	jsonTree.children = new Array();

    for (filesCollection.moveFirst(); !filesCollection.atEnd(); filesCollection.moveNext()) {  
        fileObj = filesCollection.item(); 
        var nm = fileObj.Name;
        if(isFlowFileName(nm)) 
        {
        	checkForImports(fileObj);
        	var obj = new Object();
        	obj.name = nm;
        	jsonTree.children.push(obj);
        }
	}

	var Collection = new Enumerator(folderObj.SubFolders);  

    var Obj;  
  	
    for (Collection.moveFirst(); !Collection.atEnd(); Collection.moveNext()) {  
        Obj = Collection.item();  
        jsonTree.children.push(new Object());
        var last = jsonTree.children.length-1;
        ReadFlowFiles(jsonTree.children[last], Obj); 
	}    
	if(jsonTree.children.length==0) delete jsonTree.children;
}  
  
function ReadAllFlow(){
		var fso = new ActiveXObject("Scripting.FileSystemObject"); 
		//var path = "C:\\LSTree"; 
		var path = "C:\\copenhagen\\flow\\smartbuilder\\probes";
		var tree = new Object();
	    // object created for folder object returned by GetFolder method  
	    var folderObj = fso.GetFolder(path); 
	    ReadFlowFiles(tree, folderObj);
	    //var file = fso.CreateTextFile("C:\\LSTree\\ls.json", true); // Создаем файл
		//file.WriteLine(JSON.stringify(tree)); // Выводим в него строку
		file.Close(); // Закрываем файл
}

function isFlowFileName(str)
{
	return str.lastIndexOf(".flow") == str.length - 5;
}

function importStrIsIncluded(str)
{
	return str.indexOf("import") >= 0;
}

function checkForImports(fileObj)
{
	var fs = new ActiveXObject("Scripting.FileSystemObject");
	var filePath = fileObj.Path;
	//alert(filePath);
	var strf = fs.OpenTextFile(filePath);
	var line = "";
	var target = "";
	var source = getName(fileObj.Path);
	var buff = "";
	var count = 0;
	while(!strf.AtEndOfStream)
	{
		line = strf.ReadLine();
		if(importStrIsIncluded(line)) {
			line = line.substring(0, line.length-1);
			target = line.substring(7);
			//alert(source +","+target);
			writeToCsv(source, target);
		}
		count++;
		if(count>40) break;
	}
	strf.Close();
}

function getName(str)
{
	var len = 0;
	var s1 = "C:\\copenhagen\\flow\\flow";
	var s2 = "C:\\copenhagen\\flow";
	//var s1 = "C:\\LSTree\\flow";
	//var s2 = "C:\\LSTree";
	var pos = str.indexOf(s1);
	if (pos>=0) {
		var b1 = str.substr(s1.length + 2);
		return b1.substr(0, b1.length -5);
	}
	var b2 = str.substr(s2.length)
	return b2.substr(0, b2.length -5);
}
function writeToCsv(src, trg)
{
	var fso = new ActiveXObject("Scripting.FileSystemObject"); 
	var file = fso.OpenTextFile("C:\\LSTree\\force2.csv",8,true); 
	file.WriteLine(src+","+trg+","+"0.2");
	file.Close();
}