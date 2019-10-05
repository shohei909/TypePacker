package typepacker.bytes;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesOutput;
import haxe.io.Output;
import typepacker.bytes.BytesPrinter.OutputMode;
import typepacker.core.PackerSetting;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;
import yaml.util.IntMap;

class BytesPrinter
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
	
	public function printBytesWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        _printBytesWithInfo(
			info,
			data,
			output,
			OutputMode.Unknown
		);
    }
	private function _printBytesWithInfo(info:TypeInformation<Dynamic>, data:Dynamic, output:Output, mode:OutputMode):OutputMode 
	{
		switch (info) {
            case TypeInformation.PRIMITIVE(nullable, type)                                       : printPrimitive(nullable, type, data, output);
            case TypeInformation.STRING                                                          : mode = printString(data, output, mode); 
            case TypeInformation.ENUM(_, _, keys, constractors)                                  : mode = printEnum(keys, constractors, data, output, mode);
            case TypeInformation.CLASS(_, _, fields, fieldNames) | ANONYMOUS(fields, fieldNames) : mode = printClassInstance(fields, fieldNames, data, output, mode);
            case TypeInformation.MAP(STRING, value)                                              : mode = printStringMap(value, data, output, mode);
            case TypeInformation.MAP(INT, value)                                                 : mode = printIntMap(value, data, output, mode);
            case TypeInformation.COLLECTION(elementType, type)                                   : mode = printCollection(elementType, type, data, output, mode);
            case TypeInformation.ABSTRACT(type)                                                  : mode = printAbstract(type, data, output, mode);
            case TypeInformation.CLASS_TYPE                                                      : mode = printClassType(data, output, mode);
            case TypeInformation.ENUM_TYPE                                                       : mode = printEnumType(data, output, mode);
        }
		return mode;
	}
    private function printPrimitive(nullable:Bool, type:PrimitiveType, data:Dynamic, output:Output):Void 
	{
		if (nullable || setting.forceNullable) {
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
	private function printString(data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		if (data == null) {
			output.writeByte(0xFF);
			return mode;
		} else {
			output.writeByte(0);
		}
		return _printString(data, output, mode);
	}
	private function _printString(data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		switch (mode)
		{
			#if flash
			case OutputMode.Bytes:
				var string:String = data;
				var byteArray:flash.utils.ByteArray = untyped output.b;
				byteArray.endian = if (output.bigEndian) flash.utils.Endian.BIG_ENDIAN else flash.utils.Endian.LITTLE_ENDIAN;
				byteArray.writeUTF(string);
				byteArray.endian = flash.utils.Endian.LITTLE_ENDIAN;
			#end
			
			case OutputMode.WriteUtf:
				untyped output.__writeUTF(data);
				
			case OutputMode.Any:
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
				_printString(data, output, mode);
		}
		return mode;
	}
	private function printEnum(keys:Map<String, Int>, constructors:Map<Int, Array<String>>, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		if (data == null) {
			output.writeByte(0xFF);
			return mode;
		} else {
			output.writeByte(0);
		}
		
		var index:Int;
		if (setting.useEnumIndex)
		{
			index = Type.enumIndex(data);
			output.writeUInt16(index);
		}
		else
		{
			var c = Type.enumConstructor(data);
			index = keys[c];
			mode = _printString(c, output, mode);
		}
        var parameterTypes = constructors[index];
        var parameters = Type.enumParameters(data);
		
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
	private function printClassInstance(fields:Map<String, String>, fieldNames:Array<String>, data:Dynamic, output:Output, mode:OutputMode):OutputMode
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
	private function printStringMap(type:String, data:Dynamic, output:Output, mode:OutputMode):OutputMode
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
	private function printIntMap(type:String, data:Dynamic, output:Output, mode:OutputMode):OutputMode
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
	private function printCollection(elementType:String, type:CollectionType, data:Dynamic, output:Output, mode:OutputMode):OutputMode
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
	private function printAbstract(type:String, data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		return _printBytesWithInfo(
			TypePacker.resolveType(type), 
			data, 
			output, 
			mode
		);
	}
	private function printClassType(data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		return printString(Type.getClassName(data), output, mode);
	}
	private function printEnumType(data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		return printString(Type.getEnumName(data), output, mode);
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
