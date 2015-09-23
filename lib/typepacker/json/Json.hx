package typepacker.json;
import typepacker.core.TypePacker;

#if macro
import haxe.macro.Expr;
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
    #end

    macro public static function print(type:String, data:Expr) {
        var info = TypePacker.toTypeInfomation(type);
        return macro typepacker.json.Json.defaultPacker.printWithInfo($info, $data);
    }

    macro public static function parse(type:String, data:Expr) {
        var info = TypePacker.toTypeInfomation(type);
        return macro typepacker.json.Json.defaultPacker.parseWithInfo($info, $data);
    }
}
