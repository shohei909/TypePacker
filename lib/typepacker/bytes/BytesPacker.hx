package typepacker.bytes;
import typepacker.bytes.BytesSerializer;

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
    public var serializer(default, null):BytesSerializer;
    public var unserializer(default, null):BytesUnserialzer;
    
    public function new(?setting:PackerSetting) {
        if (setting == null)
        {
            setting = new PackerSetting();
            setting.useEnumIndex = true;
        }
        this.setting = setting;
        this.serializer = new BytesSerializer(setting);
        this.unserializer = new BytesUnserialzer(setting);
    }
    public function serializeWithInfo<T>(info:TypeInformation<T>, data:T, output:Output):Void {
        return serializer.serializeWithInfo(info, data, output);
    }

    public function unserializeWithInfo<T>(info:TypeInformation<T>, input:Input):T {
        return unserializer.unserializeWithInfo(info, input);
    }
    #end
    
}
