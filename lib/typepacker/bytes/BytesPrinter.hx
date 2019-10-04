package typepacker.bytes;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesOutput;
import haxe.io.Output;
import typepacker.core.TypeInformation;

class BytesPrinter
{
	private static var bytesBuffer:BytesBuffer;
	
	public static function printBytesWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        return _printBytesWithInfo(
			info,
			data,
			output,
			OutputMode.Unknown
		);
    }
	private static function _printBytesWithInfo(info:TypeInformation<Dynamic>, data:Dynamic, output:Output, mode:OutputMode):Void 
	{
		switch(info) {
            case TypeInformation.PRIMITIVE(nullable, type)            : printPrimitive(type, data);
            case TypeInformation.STRING                               : mode = printString(data, output, mode); 
            case TypeInformation.ENUM(_, constractors)                : mode = printEnum(constractors, data, output, mode);
            case TypeInformation.CLASS(_, fields) | ANONYMOUS(fields) : mode = printClassInstance(fields, data, output, mode);
            case TypeInformation.MAP(STRING, value)                   : mode = printStringMap(value, output, mode);
            case TypeInformation.MAP(INT, value)                      : mode = printIntMap(value, output, mode);
            case TypeInformation.COLLECTION(elementType, type)        : mode = printCollection(elementType, type, data, output, mode);
            case TypeInformation.ABSTRACT(type)                       : mode = printAbstract(type, data, output, mode);
        }
		return mode;
	}
    private static function printPrimitive(type:PrimitiveType, data:Dynamic, output:Output):Dynamic 
	{
        switch (type) {
            case PrimitiveType.INT   : output.writeInt32(data);
            case PrimitiveType.BOOL  : output.writeByte(if (data) 1 else 0);
            case PrimitiveType.FLOAT : output.writeDouble(data);
        }
    }
	private static function printString(data:Dynamic, output:Output, mode:OutputMode):OutputMode
	{
		return switch (mode)
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
				#if neko
				var length = untyped __dollar__ssize(bytes.length);
				output.writeUInt16(length);
				output.writeString(string);
				#else
				printBytes(Bytes.ofString(data), output);
				#end
				
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
	}
	private static function printBytes(data:Dynamic, output:Output):Void
	{
		var bytes:Bytes = data;
		var length = bytes.length;
		output.writeUInt16(length);
		output.writeBytes(bytes, 0, length);
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
