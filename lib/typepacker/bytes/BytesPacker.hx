package typepacker.bytes;
import typepacker.bytes.BytesPrinter;

#if macro
import haxe.macro.ExprTools;
import haxe.format.JsonParser;
import haxe.format.JsonPrinter;
import haxe.macro.Expr;
import haxe.macro.Context;
#else
import haxe.io.Input;
import haxe.io.Output;
import typepacker.core.PackerSetting;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;
#end

class BytesPacker
{
    #if !macro
    public var setting(default, null):PackerSetting;
	public var printer(default, null):BytesPrinter;
	public var parser(default, null):BytesParser;
	
    public function new(?setting:PackerSetting) {
		if (setting == null)
		{
			setting = new PackerSetting();
			setting.useEnumIndex = true;
		}
        this.setting = setting;
        this.printer = new BytesPrinter(setting);
        this.parser = new BytesParser(setting);
    }
    public function printBytesWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        return printer.printBytesWithInfo(info, data, output);
    }

    public function parseBytesWithInfo<T>(info:TypeInformation<T>, input:Input):T {
        return parser.parseBytesWithInfo(info, input);
    }
	#end
	 
    macro public function print(self:Expr, type:String, data:Expr, output:Expr) {
        var complexType = TypePacker.stringToComplexType(type);
        var info = TypePacker.complexTypeToTypeInformation(complexType);
        return macro $self.printWithInfo($info, ($data : $complexType));
    }

    macro public function parse(self:Expr, type:String, input:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro $self.parseWithInfo($info, $data);
    }
}
