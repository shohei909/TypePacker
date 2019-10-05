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
	public var serializeer(default, null):BytesPrinter;
	public var unserializer(default, null):BytesParser;
	
    public function new(?setting:PackerSetting) {
		if (setting == null)
		{
			setting = new PackerSetting();
			setting.useEnumIndex = true;
		}
        this.setting = setting;
        this.serializeer = new BytesPrinter(setting);
        this.unserializer = new BytesParser(setting);
    }
    public function serializeWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        return serializeer.serializeWithInfo(info, data, output);
    }

    public function unserializeWithInfo<T>(info:TypeInformation<T>, input:Input):T {
        return unserializer.unserializeWithInfo(info, input);
    }
	#end
	 
    macro public function serialize(self:Expr, type:String, data:Expr, output:Expr) {
        var complexType = TypePacker.stringToComplexType(type);
        var info = TypePacker.complexTypeToTypeInformation(complexType);
        return macro $self.serializeWithInfo($info, ($data : $complexType));
    }

    macro public function unserialize(self:Expr, type:String, input:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro $self.unserializeWithInfo($info, $data);
    }
}
