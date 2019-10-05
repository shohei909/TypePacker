package typepacker.json;

#if macro
import haxe.macro.Expr;
import typepacker.core.TypePacker;
#else
import typepacker.core.TypeInformation;
#end

class Json {
    #if !macro
    public static var defaultPacker(get, set):JsonPacker;
    private static var _defaultPacker:JsonPacker;

    public static function get_defaultPacker() {
        if (_defaultPacker == null) {
            _defaultPacker = new JsonPacker();
        }
        return _defaultPacker;
    }

    public static function set_defaultPacker(packer:JsonPacker) {
        return _defaultPacker = packer;
    }
	
    public static function printWithInfo<T>(info:TypeInformation<T>, data:T):String {
        return defaultPacker.printWithInfo(info, data);
    }

    public static function parseWithInfo<T>(info:TypeInformation<T>, data:String):T {
        return defaultPacker.parseWithInfo(info, data);
    }
    #end

    macro public static function print(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro typepacker.json.Json.printWithInfo($info, $data);
    }

    macro public static function parse(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro typepacker.json.Json.parseWithInfo($info, $data);
    }
}
