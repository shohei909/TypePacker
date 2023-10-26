package typepacker.core;

#if macro
import haxe.macro.Expr;
#end

class TypeUtil
{
	/**
	   Deep clone
	**/
    public static macro function clone(typePath:String, data:Expr) {
        var info = TypePacker.toTypeInformation(typePath);
        return macro new typepacker.core.DataCloner(
			typepacker.core.DataCloner.defaultSetting
		).execute(
			$info,
			$data
		);
    }	
	
	/**
	   Deep equal
	**/
	public static macro function isSame(typePath:String, a:Expr, b:Expr)
	{
		var info = TypePacker.toTypeInformation(typePath);
        return macro new typepacker.core.DataMatcher(
			typepacker.core.DataMatcher.defaultSetting
		).isSame(
			$info,
			$a,
			$b
		);
	}
}
