package typepacker.bytes;
import haxe.DynamicAccess;
import haxe.ds.IntMap;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.FPHelper;
import haxe.io.Input;
import haxe.io.Output;
import typepacker.core.PackerSetting;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;

class BytesUnserialzer 
{
    var setting:PackerSetting;

    public function new(?setting:PackerSetting) {
        if (setting == null)
        {
            setting = new PackerSetting();
            setting.useEnumIndex = true;
        }
        this.setting = setting;
    }
    
    public function unserializeWithInfo<T>(info:TypeInformation<T>, input:Input):T {
        return switch (info) {
            case TypeInformation.PRIMITIVE(nullable, type)                                        : unserializePrimitive(nullable, type, input);
            case TypeInformation.BYTES                                                            : unserializeBytes(input);
            case TypeInformation.STRING                                                           : unserializeString(input); 
            case TypeInformation.ENUM(name, _enum, keys, constractors, nameToAlias, aliasToName)  : unserializeEnum(name, _enum, keys, constractors, input);
            case TypeInformation.CLASS(name, _class, fields, fieldNames, nameToAlias)             : unserializeClassInstance(name, _class, fields, fieldNames, input);
            case TypeInformation.ANONYMOUS(fields, fieldNames, nameToAlias)                       : unserializeAnonymous(fields, fieldNames, input);
            case TypeInformation.MAP(STRING, value)                                               : unserializeStringMap(value, input);
            case TypeInformation.MAP(INT, value)                                                  : unserializeIntMap(value, input);
			case TypeInformation.DYNAMIC_ACCESS(value)                                            : unserializeDynamicAccess(value, input);
            case TypeInformation.COLLECTION(elementType, type)                                    : unserializeCollection(elementType, type, input);
            case TypeInformation.ABSTRACT(type)                                                   : unserializeAbstract(type, input);
            case TypeInformation.CLASS_TYPE                                                       : unserializeClassType(input);
            case TypeInformation.ENUM_TYPE                                                        : unserializeEnumType(input);
        }
    }
    private function unserializePrimitive(nullable:Bool, type:PrimitiveType, input:Input):Dynamic
    {
        if (nullable || setting.forceNullable) {
            var byte = input.readByte();
            if (byte == 0xFF) {
                return null;
            }
        }
        return switch (type) {
            case PrimitiveType.INT   : unserializeInt32(input);
            case PrimitiveType.BOOL  : input.readByte() != 0;
            case PrimitiveType.FLOAT : unserializeDouble(input);
        }
    }
    private function unserializeBytes(input:Input):Dynamic
    {
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var length = unserializeInt32(input);
        return input.read(length);
    }
    private function unserializeString(input:Input):Dynamic
    {
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var length = unserializeUInt16(input);
        return input.readString(length);
    }
    private function unserializeEnum(name:String, _enum:Enum<Dynamic>, keys:Map<String, Int>, constructors:Map<Int, Array<String>>, input:Input):Dynamic
    {
        if (_enum == null) _enum = Type.resolveEnum(name);
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var index:Int;
        if (setting.useEnumIndex)
        {
            index = unserializeUInt16(input);
        }
        else
        {
            var length = unserializeUInt16(input);
            var c:String = input.readString(length);
            index = keys[c];
        }
        var parameters = [];
        for (parameterType in constructors[index])
        {
            parameters.push(
                unserializeWithInfo(
                    TypePacker.resolveType(parameterType), 
                    input
                )
            );
        }
        return Type.createEnumIndex(_enum, index, parameters);
    }
    private function unserializeClassInstance(name:String, _class:Class<Dynamic>, fields:Map<String, String>, fieldNames:Array<String>, input:Input):Dynamic
    {
        if (_class == null) _class = Type.resolveClass(name);
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var data = Type.createEmptyInstance(_class);
        for (name in fieldNames)
        {
            var value = unserializeWithInfo(
                TypePacker.resolveType(fields[name]), 
                input
            );
            Reflect.setField(data, name, value);
        }
        return data;
    }
    private function unserializeAnonymous(fields:Map<String, String>, fieldNames:Array<String>, input:Input):Dynamic
    {
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var data = {};
        for (name in fieldNames)
        {
            var value = unserializeWithInfo(
                TypePacker.resolveType(fields[name]), 
                input
            );
            Reflect.setField(data, name, value);
        }
        return data;
    }
    private function unserializeStringMap(type:String, input:Input):Dynamic
    {
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var map:StringMap<Dynamic> = new StringMap();
        var typeInfo = TypePacker.resolveType(type);
        var size = unserializeUInt16(input);
        for (i in 0...size) 
        {
            var key = unserializeString(input);
            var value = unserializeWithInfo(
                typeInfo,
                input
            );
            map.set(key, value);
        }
        return map;
    }
    private function unserializeIntMap(type:String, input:Input):Dynamic
    {
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var map:IntMap<Dynamic> = new IntMap();
        var typeInfo = TypePacker.resolveType(type);
        var size = unserializeUInt16(input);
        for (i in 0...size) 
        {
            var key = unserializeInt32(input);
            var value = unserializeWithInfo(
                typeInfo,
                input
            );
            map.set(key, value);
        }
        return map;
    }
    private function unserializeDynamicAccess(type:String, input:Input):Dynamic
    {
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var map:DynamicAccess<Dynamic> = {};
        var typeInfo = TypePacker.resolveType(type);
        var size = unserializeUInt16(input);
        for (i in 0...size) 
        {
            var key = unserializeString(input);
            var value = unserializeWithInfo(
                typeInfo,
                input
            );
            map.set(key, value);
        }
        return map;
    }
    private function unserializeCollection(elementType:String, type:CollectionType, input:Input):Dynamic
    {
        var byte = input.readByte();
        if (byte == 0xFF) {
            return null;
        }
        var typeInfo = TypePacker.resolveType(elementType);
        var length = unserializeUInt16(input);
        return switch (type)
        {
            case CollectionType.ARRAY:
                var arr:Array<Dynamic> = [];
                for (i in 0...length) {
                    arr.push(
                        unserializeWithInfo(
                            typeInfo,
                            input
                        )
                    );
                }
                arr;
                
            case CollectionType.LIST:
                var arr:List<Dynamic> = new List();
                for (i in 0...length) {
                    arr.add(
                        unserializeWithInfo(
                            typeInfo,
                            input
                        )
                    );
                }
                arr;
                
            case CollectionType.VECTOR:
                var vec:Vector<Dynamic> = new Vector(length);
                for (i in 0...length) {
                    vec[i] = unserializeWithInfo(
                        typeInfo,
                        input
                    );
                }
                vec;
        }
    }
    private function unserializeAbstract(type:String, input:Input):Dynamic
    {
        return unserializeWithInfo(
            TypePacker.resolveType(type), 
            input
        );
    }
    private function unserializeClassType(input:Input):Dynamic
    {
        return Type.resolveClass(unserializeString(input));
    }
    private function unserializeEnumType(input:Input):Dynamic
    {
        return Type.resolveEnum(unserializeString(input));
    }
    private function unserializeInt32(input:Input):Int {
        var ch1 = input.readByte();
        var ch2 = input.readByte();
        var ch3 = input.readByte();
        var ch4 = input.readByte();
        return (ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1;
    }
    private function unserializeUInt16(input:Input):Int {
        var ch1 = input.readByte();
        var ch2 = input.readByte();
        return (ch2 << 8) | ch1;
    }
    private function unserializeDouble(input:Input):Float {
        var i1 = unserializeInt32(input);
        var i2 = unserializeInt32(input);
        return FPHelper.i64ToDouble(i1, i2);
    }
}
