package typepacker.bytes;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesOutput;
import haxe.io.Output;
import typepacker.bytes.BytesPrinter.OutputMode;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;
import yaml.util.IntMap;

class BytesPrinter
{
	public static function printBytesWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        _printBytesWithInfo(
			info,
			data,
			output,
			OutputMode.Unknown
		);
    }
	private static function _printBytesWithInfo(info:TypeInformation<Dynamic>, data:Dynamic, output:Output, mode:OutputMode):OutputMode 
	{
		switch (info) {
            case TypeInformation.PRIMITIVE(nullable, type)                                       : printPrimitive(nullable, type, data, output);
            case TypeInformation.STRING                                                          : mode = printString(data, output, mode); 
            case TypeInformation.ENUM(_, _, _, constractors)                                     : mode = printEnum(constractors, data, output, mode);
            case TypeInformation.CLASS(_, _, fields, fieldNames) | ANONYMOUS(fields, fieldNames) : mode = printClassInstance(fields, fieldNames, data, output, mode);
            case TypeInformation.MAP(STRING, value)                                              : mode = printStringMap(value, data, output, mode);
            case TypeInformation.MAP(INT, value)                                                 : mode = printIntMap(value, data, output, mode);
            case TypeInformation.COLLECTION(elementType, type)                                   : mode = printCollection(elementType, type, data, output, mode);
            case TypeInformation.ABSTRACT(type)                                                  : mode = printAbstract(type, data, output, mode);
            case TypeInformation.CLASS_TYPE                                                      : mode = printClassType(data, output, mode);
        }
		return mode;
	}
    private static function printPrimitive(nullable:Bool, type:PrimitiveType, data:Dynamic, output:Output):Void 
	{
		if (nullable) {
			if (data == null) {
				output.writeByte(0xFF);
				return;
			} else {
				output.writeByte(0);
			}
		}
		
        switch (type) {
            case PrimitiveType.INT   : output.writeInt32(data);
            case PrimitiveType.BOOL  : output.writeByte(if (data) 1 else 0);
            case PrimitiveType.FLOAT : output.writeDouble(data);
        }
    }
	private static function printString(data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		switch (mode)
		{
			#if flash
			case OutputMode.Bytes:
				if (data == null) {
					output.writeByte(0xFF);
					return mode;
				} else {
					output.writeByte(0);
				}
				var string:String = data;
				var byteArray:flash.utils.ByteArray = untyped output.b;
				byteArray.endian = if (output.bigEndian) flash.utils.Endian.BIG_ENDIAN else flash.utils.Endian.LITTLE_ENDIAN;
				byteArray.writeUTF(string);
				byteArray.endian = flash.utils.Endian.LITTLE_ENDIAN;
			#end
			
			case OutputMode.WriteUtf:
				if (data == null) {
					output.writeByte(0xFF);
					return mode;
				} else {
					output.writeByte(0);
				}
				untyped output.__writeUTF(data);
				
			case OutputMode.Any:
				if (data == null) {
					output.writeByte(0xFF);
					return mode;
				} else {
					output.writeByte(0);
				}
				var string:String = data;
				var bytes:Bytes = Bytes.ofString(data);
				var length = bytes.length;
				output.writeUInt16(length);
				output.writeBytes(bytes, 0, length);
				
			case OutputMode.Unknown:
				mode = 
				#if flash
				if (Std.is(output, BytesOutput)) {
					OutputMode.Bytes;
				} else 
				#end
				if (Reflect.hasField(output, "__writeUTF")) {
					OutputMode.WriteUtf;
				} else {
					OutputMode.Any;
				}
				printString(data, output, mode);
		}
		return mode;
	}
	private static function printEnum(constructors:Map<Int, Array<String>>, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		if (data == null) {
			output.writeByte(0xFF);
			return mode;
		} else {
			output.writeByte(0);
		}
		var index = Type.enumIndex(data);
		var parameters = Type.enumParameters(data);
		var parameterTypes = constructors[index];
		
		output.writeUInt16(index);
		for (i in 0...parameterTypes.length)
		{
			mode = _printBytesWithInfo(
				TypePacker.resolveType(parameterTypes[i]), 
				parameters[i], 
				output, 
				mode
			);
		}
		return mode;
	}
	private static function printClassInstance(fields:Map<String, String>, fieldNames:Array<String>, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		if (data == null) {
			output.writeByte(0xFF);
			return mode;
		} else {
			output.writeByte(0);
		}
		for (name in fieldNames)
		{
			mode = _printBytesWithInfo(
				TypePacker.resolveType(fields[name]), 
				Reflect.field(data, name), 
				output, 
				mode
			);
		}
		return mode;
	}
	private static function printStringMap(type:String, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		if (data == null) {
			output.writeByte(0xFF);
			return mode;
		} else {
			output.writeByte(0);
		}
		var map:StringMap<Dynamic> = data;
		var typeInfo = TypePacker.resolveType(type);
		var size = 0;
		for (key in map.keys()) size += 1;
		output.writeUInt16(size);
		for (key in map.keys()) 
		{
			mode = printString(key, output, mode);
			mode = _printBytesWithInfo(
				typeInfo,
				map.get(key), 
				output, 
				mode
			);
		}
		return mode;
	}
	private static function printIntMap(type:String, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		if (data == null) {
			output.writeByte(0xFF);
			return mode;
		} else {
			output.writeByte(0);
		}
		var map:IntMap<Dynamic> = data;
		var typeInfo = TypePacker.resolveType(type);
		var size = 0;
		for (key in map.keys()) size += 1;
		output.writeUInt16(size);
		for (key in map.keys()) 
		{
			output.writeInt32(key);
			mode = _printBytesWithInfo(
				typeInfo,
				map.get(key), 
				output, 
				mode
			);
		}
		return mode;
	}
	private static function printCollection(elementType:String, type:CollectionType, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		if (data == null) {
			output.writeByte(0xFF);
			return mode;
		} else {
			output.writeByte(0);
		}
		var typeInfo = TypePacker.resolveType(elementType);
		switch (type)
		{
			case CollectionType.ARRAY:
				var arr:Array<Dynamic> = data;
				output.writeUInt16(arr.length);
				for (element in arr) {
					mode = _printBytesWithInfo(
						typeInfo,
						element, 
						output, 
						mode
					);
				}
			case CollectionType.LIST:
				var arr:List<Dynamic> = data;
				output.writeUInt16(arr.length);
				for (element in arr) {
					mode = _printBytesWithInfo(
						typeInfo,
						element, 
						output, 
						mode
					);
				}
			case CollectionType.VECTOR:
				var arr:Vector<Dynamic> = data;
				output.writeUInt16(arr.length);
				for (element in arr) {
					mode = _printBytesWithInfo(
						typeInfo,
						element, 
						output, 
						mode
					);
				}
		}
		return mode;
	}
	private static function printAbstract(type:String, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		return _printBytesWithInfo(
			TypePacker.resolveType(type), 
			data, 
			output, 
			mode
		);
	}
	private static function printClassType(data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		return printString(Type.getClassName(data), output, mode);
	}
}

@:enum abstract OutputMode(Int) {
	var Unknown   = 0;
	#if flash
	var ByteArray = 1;
	#end
	var WriteUtf  = 2;
	var Any       = 3;
}
