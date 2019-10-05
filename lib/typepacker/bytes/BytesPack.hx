package typepacker.bytes;

#if macro
import haxe.macro.Expr;
import typepacker.core.TypePacker;
#else
import haxe.io.Input;
import haxe.io.Output;
import typepacker.core.TypeInformation;
#end


class BytesPack 
{
    #if !macro
    public static var defaultPacker(get, set):BytesPacker;
    private static var _defaultPacker:BytesPacker;
    public static function get_defaultPacker() {
        if (_defaultPacker == null) {
            _defaultPacker = new BytesPacker();
        }
        return _defaultPacker;
    }
    public static function set_defaultPacker(packer:BytesPacker) {
        return _defaultPacker = packer;
    }

    public static function serializeWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        return defaultPacker.serializeWithInfo(info, data, output);
    }

    public static function unserializeWithInfo<T>(info:TypeInformation<T>, input:Input):T {
        return defaultPacker.unserializeWithInfo(info, input);
    }
    #end

    macro public static function serialize(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro {
			var output = new haxe.io.BytesOutput();
			typepacker.bytes.BytesPack.serializeWithInfo($info, $data, output);
			output.getBytes();
		}
    }

    macro public static function unserialize(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro {
			var input = new haxe.io.BytesInput($data);
			typepacker.bytes.BytesPack.unserializeWithInfo($info, input);
		}
    }
}