package typepacker.core;
import haxe.ds.Vector;

enum TypeInfomation<T>
{
    ANONYMOUS(fieldTypes:Map<String,String>);
    CLASS(type:String, fieldTypes:Map<String,String>);
    ENUM(type:String, constructors:Map<String, Array<String>>);
    MAP(keyType:MapKeyType, valueType:String);
    ABSTRACT(baseType:String);
    COLLECTION(elementType:String, type:CollectionType);
    PRIMITIVE(nullable:Bool, type:PrimitiveType);
    STRING;
}

enum MapKeyType {
    STRING;
    INT;
}

enum PrimitiveType {
    INT;
    BOOL;
    FLOAT;
}

enum CollectionType {
    ARRAY;
    LIST;
    VECTOR;
}
