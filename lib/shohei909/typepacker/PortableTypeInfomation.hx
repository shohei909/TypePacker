package shohei909.typepacker;

enum PortableTypeInfomation<T>
{
    ANONYMOUS(fieldTypes:Map<String,String>);
    CLASS(type:String, fieldTypes:Map<String,String>);
    ENUM(type:String, constructors:Map<String, Array<String>>);
    STRING_MAP(valueType:String);
    ABSTRACT(baseType:String);
    ARRAY(elementType:String);
    INT(nullable:Bool);
    BOOL(nullable:Bool);
    FLOAT(nullable:Bool);
    STRING;
}
