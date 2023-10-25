package typepacker.core;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr.FieldType;
import haxe.macro.Expr.Access;
import haxe.macro.Type;

class CloneBuild 
{
	public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		var type   = Context.getLocalType();
		var pos    = Context.currentPos();
		switch (type)
		{
			case Type.TInst(classType, params):
				if (Lambda.exists(fields, function(field) return field.name == "clone"))
				{
					return fields;
				}
				var access = [Access.APublic];
				if (TypeTools.findField(classType.get(), "clone", false) != null)
				{
					access.push(Access.AOverride);
				}
				var typeName = TypeTools.toString(type);
				
				fields.push({
					name: "clone",
					access: access,
					kind: FieldType.FFun({
						expr: macro {
							return new typepacker.core.DataCloner(typepacker.core.DataCloner.defaultSetting).execute(
								typepacker.core.TypePacker.toTypeInformation($v{typeName}),
								this,
								true
							); 
						},
						ret: TypeTools.toComplexType(type),
						args: [],
					}),
					pos: pos,
				});
				
			case _:
		}
		
		return fields;
	}
}
#end
