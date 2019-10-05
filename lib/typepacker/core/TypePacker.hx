package typepacker.core;


#if macro
import haxe.EnumTools.EnumValueTools;
import haxe.ds.IntMap;
import haxe.ds.Map;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.macro.Printer;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type in MacroType;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.TypeParameter;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
#else
import haxe.Resource;
#end

class TypePacker
{
    #if !macro
    macro
    #end
    public static function toTypeInformation(e:String):Expr {
        return complexTypeToTypeInformation(stringToComplexType(e));
    }

    #if !macro
    public static function resolveType<T>(name:String):TypeInformation<T> {
        return TypePackerResource.registered[name];
    }
    #else
    public static var registered:Map<String, Dynamic> = new Map();

    public static function complexTypeToTypeInformation(complexType:ComplexType):Expr {
        var pos = Context.currentPos();
        var name = registerType(ComplexTypeTools.toType(complexType));
        var infoType = macro: typepacker.core.TypeInformation<$complexType>;
        return macro (typepacker.core.TypePacker.resolveType($v{name}) : $infoType);
    }

    public static function stringToComplexType(str:String) {
        var expr = Context.parse("(_:" + str + ")", Context.currentPos());
        return switch (expr) {
            case { expr : EParenthesis({expr : ECheckType(_, type)}) }:
                type;
            case _:
                throw "invalid complex type";
        }
    }

    private static function isNullType(t:MacroType) {
        var nullType = macro : StdTypes.Null;
        var ct = Context.toComplexType(t);

        return switch [ct, nullType] {
            case [TPath(p1), TPath(p2)]:
                (p1.sub == p2.sub && p1.name == p2.name && p1.pack.join(".") == p2.pack.join("."));

            default:
                false;
        }
    }

    private static function getTypeName(t:MacroType) {
        return TypeTools.toString(t);
    }

    public static function registerType(type:MacroType) {
        
        
        return _registerType(type, new Map());
    }
    
    private static function _registerType(type:MacroType, paramsMap:Map<String, MacroType>) {
        var tmpName = getTypeName(type);
        type = if (paramsMap.exists(tmpName))
        {
            paramsMap[tmpName];
        }
        else
        {
            TypeTools.map(type, applyTypeParams.bind(paramsMap));
        }
        
        var name = getTypeName(type);
        if (paramsMap.exists(name)) {
            return getTypeName(paramsMap[name]);
        }
        if (registered.exists(name)) {
            return name;
        }
        
        var t = type, prevT = null;
        var nullable = false;
		registered[name] = null;
        
        do {
            if (isNullType(t)) {
                nullable = true;
            }
			switch (t) 
			{
				case TAbstract(_.toString() => "Null", [element]): 
					t = element;
					nullable = true;
				case _:
			}
			
			prevT = t;
            t = Context.follow(t, true);
        } while (getTypeName(prevT) != getTypeName(t));
        
        var info = switch (t) {
            case TInst(_.toString() => "Array", [element]):
                TypeInformation.COLLECTION(_registerType(element, paramsMap), ARRAY);

            case TInst(_.toString() => #if(haxe_ver < 4) "List" #else "haxe.ds.List" #end, [element]):
                TypeInformation.COLLECTION(_registerType(element, paramsMap), LIST);

            case TAbstract(_.toString() => "haxe.ds.Vector", [element]):
                TypeInformation.COLLECTION(_registerType(element, paramsMap), VECTOR);

            case TAbstract(_.toString() => #if(haxe_ver < 4) "Map" #else "haxe.ds.Map" #end, [TypeTools.followWithAbstracts(_) => (TInst(_.toString() => "String", [])), element]):
                TypeInformation.MAP(STRING, _registerType(element, paramsMap));

            case TAbstract(_.toString() => #if(haxe_ver < 4) "Map" #else "haxe.ds.Map" #end, [TypeTools.followWithAbstracts(_) => (TAbstract(_.toString() => "Int", [])), element]):
                TypeInformation.MAP(INT, _registerType(element, paramsMap));

            case TInst(_.toString() => "String", []) :
                TypeInformation.STRING;

            case TAbstract(_.toString() => "Float", []) :
                TypeInformation.PRIMITIVE(nullable, FLOAT);

            case TAbstract(_.toString() => "Bool", []) :
                TypeInformation.PRIMITIVE(nullable, BOOL);

            case TAbstract(_.toString() => "Int", []) :
                TypeInformation.PRIMITIVE(nullable, INT);
				
			case TAbstract(ref, [element]) if (ref.toString() == "Class"):
				TypeInformation.CLASS_TYPE;
			case TAbstract(ref, [element]) if (ref.toString() == "Enum"):
				TypeInformation.ENUM_TYPE;
				
            case TEnum(ref, params):
                
                var e = ref.get();
                var map = new Map<Int, Array<String>>();
				var keys = new Map<String, Int>();
                var childParamsMap = mapTypeParams(e.params, params);
				
				var index = 0;
                for (key in e.names) {
                    var c = e.constructs.get(key);
                    var arr = [];
                    if (c.meta.has(":noPack")) continue;
                    switch(c.type) {
                        case TEnum(_, _):
                        case TFun(args, _):
                            for (a in args) {
                                var t = a.t;
                                arr.push(_registerType(t, childParamsMap));
                            };
                        default :
                            Context.error(name + " has unsupported constractor: " + c.type, Context.currentPos());
                    }
                    map[index] = arr;
					keys[key] = index;
					index += 1;
                }
                TypeInformation.ENUM(ref.toString(), null, keys, map);

            case TInst(ref, params) :
                var struct = ref.get();
                if (struct.isInterface)
                {
                    Context.error("interface is not supported:" + name, Context.currentPos());
                }
                
                var className = struct.name;
                var map = new Map();
				var fieldNames = [];
                var childParamsMap = null;

                while (true) {
                    childParamsMap = mapTypeParams(struct.params, params, childParamsMap);
					var classFields = struct.fields.get();
					classFields.reverse();
                    mapFields(classFields, childParamsMap, map, fieldNames);

                    var superClass = struct.superClass;
                    if (superClass == null) break;
                    struct = superClass.t.get();
                    params = [];

                    for (p in superClass.params) {
                        var name = p.getName();
                        params.push(if (childParamsMap.exists(name)) childParamsMap[name] else p);
                    }
                }
				fieldNames.reverse();
                TypeInformation.CLASS(ref.toString(), null, map, fieldNames);

            case TAnonymous(ref):
                var struct = ref.get();
                var map = new Map();
				var fieldNames = [];
				mapFields(struct.fields, null, map, fieldNames);

                TypeInformation.ANONYMOUS(map, fieldNames);

            case TAbstract(ref, params) :
                var abst = ref.get();
                var childParamsMap = mapTypeParams(abst.params, params);
                var type = abst.type;

                TypeInformation.ABSTRACT(_registerType(type, childParamsMap));

            default :
                Context.error("unspported data type " + name, Context.currentPos());
                null;
        };
        
        registered[name] = info;
        return name;
    }
    
    private static function applyTypeParams(params:Map<String, MacroType>, type:MacroType):MacroType
    {
        var name = getTypeName(type);
        return if (params.exists(name))
        {
            params[name];
        }
        else
        {
            type;
        }
    }

    private static function mapTypeParams(def:Array<TypeParameter>, actual:Array<MacroType>, prevMap:Map<String, MacroType> = null) {
        var map = new Map<String, MacroType>();
        for (i in 0...def.length) {
            var type = actual[i];
            var name = getTypeName(type);
            if (prevMap != null && prevMap.exists(name)) {
                type = prevMap[name];
            }
            map[getTypeName(def[i].t)] = type;
        }
        return map;
    }

    private static function mapFields(fields:Array<ClassField>, typeParams:Map<String, MacroType> = null, map:Map<String, String>, fieldNames:Array<String>) {
        if (typeParams == null)
        {
            typeParams = new Map();
        }
        for (f in fields) {
            if (f.meta.has(":noPack")) continue;

            switch (f.kind) {
                case FMethod(_):
                    continue;
                default:
            }

            var type = f.type;
            
            map[f.name] = _registerType(type, typeParams);
			fieldNames.push(f.name);
        }
    }
	
	private static var defined:Bool = false;
	private static function onAfterTyping(types:Array<haxe.macro.Type.ModuleType>):Void
	{
		if (defined) return;
		defined = true;
		// see https://github.com/HaxeFoundation/haxe/issues/6254#issuecomment-502017733
		var expr = makeExpr(registered);
		var type = macro class TypePackerResource2 {
			@:keep public static var registered:Map<String, Dynamic> = $expr;
		};
		type.meta.push({name:"@:keep", pos:Context.currentPos()});
		Context.defineType(type);
		Compiler.exclude("TypePackerResource");
	}
	
	private static function makeExpr(value:Dynamic):Expr
	{
		return if (Std.is(value, IntMap) || Std.is(value, StringMap))
		{
			var mapExpr:Array<Expr> = [];
			for (key in (value.keys(): Iterator<Int>))
			{
				mapExpr.push(macro $v{key} => ${makeExpr(value.get(key))});
			}
			if (mapExpr.length == 0) macro new Map() else macro $a{mapExpr};
		} 
		else if (Reflect.isEnumValue(value))
		{
			var typeNameString = Type.getEnumName(Type.getEnum(value));
			var typeName = typeNameString.split(".");
			var name = EnumValueTools.getName(value);
			var params = EnumValueTools.getParameters(value);
			if (params.length == 0)
			{
				macro $p{typeName}.$name;
			}
			else
			{
				var paramExprs = [for (param in params) makeExpr(param)];
				if (typeNameString == "typepacker.core.TypeInformation")
				{
					if (name == "CLASS")
					{
						paramExprs[1] = macro Type.resolveClass($v{params[0]});
					}
					else if (name == "ENUM")
					{
						paramExprs[1] = macro Type.resolveEnum($v{params[0]});
					}
				}
				macro $p{typeName}.$name($a{paramExprs});
			}
		}
		else
		{
			Context.makeExpr(value, Context.currentPos());
		}
	}
    #end
	
	public macro static function build():Array<Field>
	{
		Context.onAfterTyping(onAfterTyping);
		return null;
	}
}
