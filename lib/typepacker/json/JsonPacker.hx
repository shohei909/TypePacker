package typepacker.json;
import typepacker.core.PackerBase;
import typepacker.core.PackerSetting;

class JsonPacker extends PackerBase {
    public function new(basePrint:Dynamic->String = null, baseParse:String->Dynamic = null) {
        if (basePrint == null) {
            basePrint = haxe.Json.stringify.bind(_);
        }
        if (baseParse == null) {
            baseParse = haxe.Json.parse;
        }

        var setting = new PackerSetting();
        super(basePrint, baseParse, setting);
    }
}
