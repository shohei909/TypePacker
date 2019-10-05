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

    public static function printBytesWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        return defaultPacker.printBytesWithInfo(info, data, output);
    }

    public static function parseBytesWithInfo<T>(info:TypeInformation<T>, input:Input):T {
        return defaultPacker.parseBytesWithInfo(info, input);
    }
    #end

    macro public static function print(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro typepacker.bytes.BytesPack.printBytesWithInfo($info, $data);
    }

    macro public static function parse(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro typepacker.bytes.BytesPack.parseBytesWithInfo($info, $data);
    }
	
}