package typepacker.core;

import haxe.io.Bytes;
import haxe.macro.Printer;

#if macro
import haxe.Serializer;
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
import haxe.Unserializer;
#end

class TypePacker
{
    private static var resourceName:String = Type.getClassName(TypePacker) + ".registered";
    private static var registered:Map<String, Dynamic> = null;

    #if !macro
    macro
    #end
    public static function toTypeInfomation(e:String):Expr {
        return complexTypeToTypeInfomation(stringToComplexType(e));
    }

    #if !macro
    public static function resolveType<T>(name:String):TypeInfomation<T> {
        if (registered == null) {
            registered = Unserializer.run(Resource.getString(resourceName));
        }
        return registered[name];
    }
    #else

    public static function complexTypeToTypeInfomation(complexType:ComplexType):Expr {
        var pos = Context.currentPos();
        var name = registerType(ComplexTypeTools.toType(complexType));
        var infoType = macro: typepacker.core.TypeInfomation<$complexType>;
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
        if (registered == null) {
            registered = new Map();
            Context.onGenerate(function (array:Array<MacroType>) {
                Context.addResource(resourceName, Bytes.ofString(Serializer.run(registered)));
            });
        }
        
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
            prevT = t;
            t = Context.follow(t, true);
        } while (getTypeName(prevT) != getTypeName(t));
        
        var info = switch (t) {
            case TInst(_.toString() => "Array", [element]):
                TypeInfomation.COLLECTION(_registerType(element, paramsMap), ARRAY);

            case TInst(_.toString() => "List", [element]):
                TypeInfomation.COLLECTION(_registerType(element, paramsMap), LIST);

            case TAbstract(_.toString() => "haxe.ds.Vector", [element]):
                TypeInfomation.COLLECTION(_registerType(element, paramsMap), VECTOR);

            case TAbstract(_.toString() => "Map", [TInst(_.toString() => "String", []), element]):
                TypeInfomation.MAP(STRING, _registerType(element, paramsMap));

            case TAbstract(_.toString() => "Map", [TAbstract(_.toString() => "Int", []), element]):
                TypeInfomation.MAP(INT, _registerType(element, paramsMap));

            case TInst(_.toString() => "String", []) :
                TypeInfomation.STRING;

            case TAbstract(_.toString() => "Float", []) :
                TypeInfomation.PRIMITIVE(nullable, FLOAT);

            case TAbstract(_.toString() => "Bool", []) :
                TypeInfomation.PRIMITIVE(nullable, BOOL);

            case TAbstract(_.toString() => "Int", []) :
                TypeInfomation.PRIMITIVE(nullable, INT);

            case TEnum(ref, params):
                
                var e = ref.get();
                var map = new Map<String, Array<String>>();
                var childParamsMap = mapTypeParams(e.params, params);

                for (key in e.constructs.keys()) {
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
                            Context.error(name + " has unsupported constractor", Context.currentPos());
                    }
                    map[key] = arr;
                }
                TypeInfomation.ENUM(ref.toString(), map);

            case TInst(ref, params) :
                var struct = ref.get();
                var className = struct.name;
                var map = new Map();
                var childParamsMap = null;

                while (true) {
                    childParamsMap = mapTypeParams(struct.params, params, childParamsMap);
                    mapFields(struct.fields.get(), childParamsMap, map);

                    var superClass = struct.superClass;
                    if (superClass == null) break;
                    struct = superClass.t.get();
                    params = [];

                    for (p in superClass.params) {
                        var name = p.getName();
                        params.push(if (childParamsMap.exists(name)) childParamsMap[name] else p);
                    }
                }

                TypeInfomation.CLASS(ref.toString(), map);

            case TAnonymous(ref):
                var struct = ref.get();
                var map = mapFields(struct.fields);

                TypeInfomation.ANONYMOUS(map);

            case TAbstract(ref, params) :
                var abst = ref.get();
                var childParamsMap = mapTypeParams(abst.params, params);
                var type = abst.type;

                TypeInfomation.ABSTRACT(_registerType(type, childParamsMap));

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

    private static function mapFields(fields:Array<ClassField>, typeParams:Map<String, MacroType> = null, map:Map<String, String> = null) {
        if (map == null) map = new Map();
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
        }

        return map;
    }

    #end
}
