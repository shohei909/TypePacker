package typepacker.core;

#if macro
import haxe.macro.Expr;
#end

class Clone
{
    public static macro function clone(type:String, data:Expr) {
        var info = TypePacker.toTypeInformation(type);
        return macro new typepacker.core.DataCloner(
			defaultSetting
		).execute(
			$info,
			$data
		);
    }	
}
