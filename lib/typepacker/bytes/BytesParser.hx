package typepacker.bytes;
import haxe.ds.IntMap;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Output;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;

class BytesParser 
{
	public static function parseBytesWithInfo<T>(info:TypeInformation<T>, input:Input):T {
        return switch (info) {
            case TypeInformation.PRIMITIVE(nullable, type)               : parsePrimitive(nullable, type, input);
            case TypeInformation.STRING                                  : parseString(input); 
            case TypeInformation.ENUM(name, _enum, _, constractors)      : parseEnum(name, _enum, constractors, input);
            case TypeInformation.CLASS(name, _class, fields, fieldNames) : parseClassInstance(name, _class, fields, fieldNames, input);
			case TypeInformation.ANONYMOUS(fields, fieldNames)           : parseAnonymous(fields, fieldNames, input);
            case TypeInformation.MAP(STRING, value)                      : parseStringMap(value, input);
            case TypeInformation.MAP(INT, value)                         : parseIntMap(value, input);
            case TypeInformation.COLLECTION(elementType, type)           : parseCollection(elementType, type, input);
            case TypeInformation.ABSTRACT(type)                          : parseAbstract(type, input);
            case TypeInformation.CLASS_TYPE                              : parseClassType(input);
        }
    }
    private static function parsePrimitive(nullable:Bool, type:PrimitiveType, input:Input):Dynamic
	{
		if (nullable) {
			var byte = input.readByte();
			if (byte == 0xFF) {
				return null;
			}
		}
        return switch (type) {
            case PrimitiveType.INT   : input.readInt32();
            case PrimitiveType.BOOL  : input.readByte() != 0;
            case PrimitiveType.FLOAT : input.readDouble();
        }
    }
	private static function parseString(input:Input):Dynamic
	{
		var byte = input.readByte();
		if (byte == 0xFF) {
			return null;
		}
		var length = input.readUInt16() + byte * 0x10000;
		return input.readString(length);
	}
	private static function parseEnum(name:String, _enum:Enum<Dynamic>, constructors:Map<Int, Array<String>>, input:Input):Dynamic
	{
		if (_enum == null) _enum = Type.resolveEnum(name);
		var byte = input.readByte();
		if (byte == 0xFF) {
			return null;
		}
		var index = input.readUInt16() + byte * 0x10000;
		var parameters = [];
		for (parameterType in constructors[index])
		{
			parameters.push(
				parseBytesWithInfo(
					TypePacker.resolveType(parameterType), 
					input
				)
			);
		}
		return Type.createEnumIndex(_enum, index, parameters);
	}
	private static function parseClassInstance(name:String, _class:Class<Dynamic>, fields:Map<String, String>, fieldNames:Array<String>, input:Input):Dynamic
	{
		if (_class == null) _class = Type.resolveClass(name);
		var byte = input.readByte();
		if (byte == 0xFF) {
			return null;
		}
		var data = Type.createEmptyInstance(_class);
		for (name in fieldNames)
		{
			var value = parseBytesWithInfo(
				TypePacker.resolveType(fields[name]), 
				input
			);
			Reflect.setField(data, name, value);
		}
		return data;
	}
	private static function parseAnonymous(fields:Map<String, String>, fieldNames:Array<String>, input:Input):Dynamic
	{
		var byte = input.readByte();
		if (byte == 0xFF) {
			return null;
		}
		var data = {};
		for (name in fieldNames)
		{
			var value = parseBytesWithInfo(
				TypePacker.resolveType(fields[name]), 
				input
			);
			Reflect.setField(data, name, value);
		}
		return data;
	}
	private static function parseStringMap(type:String, input:Input):Dynamic
	{
		var byte = input.readByte();
		if (byte == 0xFF) {
			return null;
		}
		var map:StringMap<Dynamic> = new StringMap();
		var typeInfo = TypePacker.resolveType(type);
		var size = input.readUInt16() + byte * 0x10000;
		for (i in 0...size) 
		{
			var key = parseString(input);
			var value = parseBytesWithInfo(
				typeInfo,
				input
			);
			map.set(key, value);
		}
		return map;
	}
	private static function parseIntMap(type:String, input:Input):Dynamic
	{
		var byte = input.readByte();
		if (byte == 0xFF) {
			return null;
		}
		var map:IntMap<Dynamic> = new IntMap();
		var typeInfo = TypePacker.resolveType(type);
		var size = input.readUInt16() + byte * 0x10000;
		for (i in 0...size) 
		{
			var key = input.readInt32();
			var value = parseBytesWithInfo(
				typeInfo,
				input
			);
			map.set(key, value);
		}
		return map;
	}
	private static function parseCollection(elementType:String, type:CollectionType, input:Input):Dynamic
	{
		var byte = input.readByte();
		if (byte == 0xFF) {
			return null;
		}
		var typeInfo = TypePacker.resolveType(elementType);
		var length = input.readUInt16() + byte;
		return switch (type)
		{
			case CollectionType.ARRAY:
				var arr:Array<Dynamic> = [];
				for (i in 0...length) {
					arr.push(
						parseBytesWithInfo(
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
						parseBytesWithInfo(
							typeInfo,
							input
						)
					);
				}
				arr;
				
			case CollectionType.VECTOR:
				var vec:Vector<Dynamic> = new Vector(length);
				for (i in 0...length) {
					vec[i] = parseBytesWithInfo(
						typeInfo,
						input
					);
				}
				vec;
		}
	}
	private static function parseAbstract(type:String, input:Input):Dynamic
	{
		return parseBytesWithInfo(
			TypePacker.resolveType(type), 
			input
		);
	}
	private static function parseClassType(input:Input):Dynamic
	{
		return Type.resolveClass(parseString(input));
	}
}
