package shohei909.typepacker;
import haxe.format.JsonParser;
import haxe.format.JsonPrinter;

/**
 * ...
 * @author shohei909
 */
class JsonPacker
{
	public static function print<T>(typeInfo:PortableTypeInfomation<T>, data:T):String 
	{
		return JsonPrinter.print(readForPrinter(typeInfo, data));
	}
	
	public static function parse<T>(typeInfo:PortableTypeInfomation<T>, data:Dynamic):T 
	{
		return readForParser(typeInfo, JsonParser.parse(data));
	}
	
	private static function readForParser<T>(typeInfo:PortableTypeInfomation<T>, data:Dynamic):T {
		return switch(typeInfo) {
			case PortableTypeInfomation.INT(nullable) :
				if (nullable && (data == null)) {
					data;
				} else if (Std.is(data, Int)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Int");
				}
			case PortableTypeInfomation.STRING :
				if (data == null) {
					data;
				} else if (Std.is(data, String)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String");
				}
			case PortableTypeInfomation.FLOAT(nullable) :
				if (nullable && (data == null)) {
					data;
				} else if (Std.is(data, Float)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
				}
			case PortableTypeInfomation.BOOL(nullable) :
				if (nullable && (data == null)) {
					data;
				} else if (Std.is(data, Bool)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
				}
			case PortableTypeInfomation.ENUM(name, constractors):
				(enumForParser(name, constractors, data) : Dynamic);
			case PortableTypeInfomation.CLASS(name, fields) :
				(classForParser(name, fields, data) : Dynamic);
			case ANONYMOUS(fields) : 
				(objectForParser(fields, data) : Dynamic);
			case PortableTypeInfomation.STRING_MAP(value) : 
				(mapForParser(value, data) : Dynamic);
			case PortableTypeInfomation.ARRAY(type) :
				(arrayForParser(type, data) : Dynamic);
			case PortableTypeInfomation.ABSTRACT(type) :
				(abstractForParser(type, data) : Dynamic);
		}
	}
	
	private static function abstractForParser(typeString:String, data:Dynamic) {
		if (data == null) return null;
		var type = TypePacker.resolveType(typeString);
		return readForParser(type, data);
	}
	
	private static function arrayForParser(typeString:String, data:Dynamic) {
		if (data == null) return null;
		if (!Std.is(data, Array)) {
			throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
		}
		
		var result:Array<Dynamic> = [];
		var array:Array<Dynamic> = data;
		var type = TypePacker.resolveType(typeString);
		
		for (element in array) {
			result.push(readForParser(type, element));
		}
		
		return result;
	}
	
	private static function enumForParser(enumName:String, constractors:Map<String,Array<String>>, data:Dynamic):EnumValue {
		if (data == null) return null;
		if (!Std.is(data, Array)) {
			throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
		}
		
		var array:Array<Dynamic> = data;
		if (!Std.is(array[0], String)) {
			throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be string");
		}
		
		var c:String = array[0];
		var paramTypes = constractors[c];
		var params = [];
		var e = Type.resolveEnum(enumName);
		
		for (i in 0...paramTypes.length) {
			var type = TypePacker.resolveType(paramTypes[i]);
			params.push(readForParser(type, array[i + 1]));
		}
		
		return Type.createEnum(e, c, params);
	}
	
	private static function classForParser(className:String, fields:Map<String,String>, data:Dynamic):Dynamic {
		if (data == null) return null;
		var result = Type.createEmptyInstance(Type.resolveClass(className));
		for (key in fields.keys()) {
			var type = TypePacker.resolveType(fields[key]);
			var f = if (!Reflect.hasField(data, key)) {
				null;
			} else {
				Reflect.field(data, key);
			}
			
			var value = readForParser(type, f);
			Reflect.setField(result, key, value);
		}
		return result;
	}
	
	private static function objectForParser(fields:Map<String,String>, data:Dynamic):Dynamic {
		if (data == null) return null;
		var result = {};
		for (key in fields.keys()) {
			var type = TypePacker.resolveType(fields[key]);
			var f = if (!Reflect.hasField(data, key)) {
				null;
			} else {
				Reflect.field(data, key);
			}
			
			var value = readForParser(type, f);
			Reflect.setField(result, key, value);
		}
		return result;
	}
	
	private static function mapForParser(valueType:String, data:Dynamic):Map<String, Dynamic> {
		if (data == null) return null;
		var result = new Map<String, Dynamic>();
		var type = TypePacker.resolveType(valueType);
			
		for (key in Reflect.fields(data)) {
			result[key] = readForParser(type, Reflect.field(data, key));
		}
		
		return result;
	}
	
	private static function readForPrinter<T>(typeInfo:PortableTypeInfomation<T>, data:Dynamic) : T {
		return switch(typeInfo) {
			case PortableTypeInfomation.INT(nullable) :
				if (nullable && (data == null)) {
					data;
				} else if (Std.is(data, Int)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Int");
				}
			case PortableTypeInfomation.STRING :
				if (data == null) {
					data;
				} else if (Std.is(data, String)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String");
				}
			case PortableTypeInfomation.FLOAT(nullable) :
				if (nullable && (data == null)) {
					data;
				} else if (Std.is(data, Float)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
				}
			case PortableTypeInfomation.BOOL(nullable) :
				if (nullable && (data == null)) {
					data;
				} else if (Std.is(data, Bool)) {
					data;
				} else {
					throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
				}
			case PortableTypeInfomation.ENUM(_, constractors):
				(enumForPrinter(constractors, data) : Dynamic);
			case PortableTypeInfomation.CLASS(_, fields) | ANONYMOUS(fields) : 
				(objectForPrinter(fields, data) : Dynamic);
			case PortableTypeInfomation.STRING_MAP(value) : 
				(mapForPrinter(value, data) : Dynamic);
			case PortableTypeInfomation.ARRAY(type) :
				(arrayForPrinter(type, data) : Dynamic);
			case PortableTypeInfomation.ABSTRACT(type) :
				(abstractForPrinter(type, data) : Dynamic);
		}
	}
	
	
	private static function abstractForPrinter(typeString:String, data:Dynamic) {
		if (data == null) return null;
		var type = TypePacker.resolveType(typeString);
		return readForPrinter(type, data);
	}
	
	private static function arrayForPrinter(typeString:String, data:Dynamic) {
		if (data == null) return null;
		if (!Std.is(data, Array)) {
			throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
		}
		
		var result:Array<Dynamic> = [];
		var array:Array<Dynamic> = data;
		var type = TypePacker.resolveType(typeString);
		
		for (element in array) {
			result.push(readForPrinter(type, element));
		}
		
		return result;
	}
	
	private static function enumForPrinter(constractors:Map<String,Array<String>>, data:Dynamic) {
		if (data == null) return null;
		if (!Reflect.isEnumValue(data)) {
			throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be enum");
		}
		
		var result:Array<Dynamic> = [];
		
		var c = Type.enumConstructor(data);
		result.push(c);
		var paramTypes = constractors[c];
		var params = Type.enumParameters(data);
		
		for (i in 0...paramTypes.length) {
			var type = TypePacker.resolveType(paramTypes[i]);
			result.push(readForPrinter(type, params[i]));
		}
		
		return result;
	}
	
	private static function objectForPrinter(fields:Map<String,String>, data:Dynamic):Dynamic {
		if (data == null) return null;
		var result = {};
		for (key in fields.keys()) {
			var type = TypePacker.resolveType(fields[key]);
			var f = if (!Reflect.hasField(data, key)) {
				null;
			} else {
				Reflect.field(data, key);
			}
			
			var value = readForPrinter(type, f);
			Reflect.setField(result, key, value);
		}
		return result;
	}
	
	private static function mapForPrinter(valueType:String, data:Map<Dynamic, Dynamic>):Dynamic {
		if (data == null) return null;
		var result = { };
		var type = TypePacker.resolveType(valueType);
		
		for (key in data.keys()) {
			if (!Std.is(key, String)) {
				throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be String");
			} 
			var value = readForPrinter(type, data.get(key));
			Reflect.setField(result, key, value);
		}
		return result;
	}
}
