package typepacker.core;

#if macro
import haxe.macro.ExprTools;
import haxe.format.JsonParser;
import haxe.format.JsonPrinter;
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class PackerBase {

    #if !macro
    public var basePrint:Dynamic->String;
    public var baseParse:String->Dynamic;
    public var simplifier(default, null):DataSimplifier;
    public var concreter(default, null):DataConcreter;
    public var setting(default, null):PackerSetting;

    function new(basePrint:Dynamic->String, baseParse:String->Dynamic, setting:PackerSetting) {
        this.setting = setting;
        this.basePrint = basePrint;
        this.baseParse = baseParse;
        this.concreter = new DataConcreter(setting);
        this.simplifier = new DataSimplifier(setting);
    }

    public function printWithInfo<T>(info:TypeInformation<T>, data:T):String {
        return basePrint(simplifier.simplify(info, data));
    }

    public function parseWithInfo<T>(info:TypeInformation<T>, data:String):T {
        return concreter.concrete(info, baseParse(data));
    }
    #end

    macro public function print(self:Expr, type:String, data:Expr) {
        var complexType = TypePacker.stringToComplexType(type);
        var info = TypePacker.complexTypeToTypeInformation(complexType);
        return macro $self.printWithInfo($info, ($data : $complexType));
    }

    macro public function parse(self:Expr, type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro $self.parseWithInfo($info, $data);
    }

}
