package typepacker.core;
import haxe.ds.Vector;

enum TypeInformation<T>
{
    ANONYMOUS(fieldTypes:Map<String,String>, fieldNames:Array<String>, nameToAlias:Null<Map<String, String>>);
    CLASS(type:String, _class:Class<Dynamic>, fieldTypes:Map<String,String>, fieldNames:Array<String>, nameToAlias:Null<Map<String, String>>);
    ENUM(type:String, _enum:Enum<Dynamic>, keys:Map<String, Int>, constructors:Map<Int, Array<String>>);
    MAP(keyType:MapKeyType, valueType:String);
    ABSTRACT(baseType:String);
    COLLECTION(elementType:String, type:CollectionType);
    PRIMITIVE(nullable:Bool, type:PrimitiveType);
    STRING;
    CLASS_TYPE;
    ENUM_TYPE;
    BYTES;
	DYNAMIC_ACCESS(elementType:String);
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
