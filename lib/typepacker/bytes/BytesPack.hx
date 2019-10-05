package typepacker.bytes;
import haxe.io.Input;
import haxe.io.Output;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;

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
        return macro typepacker.bytes.BytesPack.serializeWithInfo($info, $data);
    }

    macro public static function unserialize(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro typepacker.bytes.BytesPack.unserializeWithInfo($info, $data);
    }
	
}