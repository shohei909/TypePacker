package typepacker.core;
import haxe.ds.Vector;

enum TypeInformation<T>
{
    ANONYMOUS(fieldTypes:Map<String,String>, fieldNames:Array<String>);
    CLASS(type:String, fieldTypes:Map<String,String>, fieldNames:Array<String>);
    ENUM(type:String, constructors:Map<String, Array<String>>, constructorNames:Array<String>);
    MAP(keyType:MapKeyType, valueType:String);
    ABSTRACT(baseType:String);
    COLLECTION(elementType:String, type:CollectionType);
    PRIMITIVE(nullable:Bool, type:PrimitiveType);
    STRING;
	CLASS_TYPE;
}

@:enum abstract MapKeyType(Int) from Int {
    var STRING = 0;
    var INT = 1;
}

@:enum abstract PrimitiveType(Int) from Int {
    var INT = 0;
    var BOOL = 1;
    var FLOAT = 2;
}

@:enum abstract CollectionType(Int) from Int {
    var ARRAY = 0;
    var LIST = 1;
    var VECTOR = 2;
}
