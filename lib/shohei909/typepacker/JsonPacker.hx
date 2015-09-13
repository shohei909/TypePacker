package shohei909.typepacker;
import haxe.format.JsonParser;
import haxe.format.JsonPrinter;
import haxe.macro.Expr;
import shohei909.typepacker.core.PackerBase;
import shohei909.typepacker.core.PortableTypeInfomation;
import shohei909.typepacker.core.PackerTools;
import shohei909.typepacker.core.TypePackerError;

/**
 * ...
 * @author shohei909
 */

class JsonPacker extends PackerBase
{
    public function new(?basePrint:Dynamic->String, ?baseParse:String->Dynamic) {
        if (basePrint == null) {
            basePrint = JsonPrinter.print.bind(_);
        }

        if (baseParse == null) {
            baseParse = JsonParser.parse;
        }

        super(basePrint, baseParse);
    }
}
