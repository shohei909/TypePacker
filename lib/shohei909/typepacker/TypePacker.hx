package shohei909.typepacker;

import haxe.crypto.Base64;
import haxe.Resource;
import haxe.Unserializer;
import haxe.io.Bytes;
#if macro
import haxe.Serializer;
import haxe.macro.Compiler;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type in MacroType;
#end

class TypePacker
{
    macro public static function toTypeInfomation(e:Expr):Expr {
        var pos = Context.currentPos();
        
        var type = switch(e.expr) {
        case EConst(CIdent(str)):
            Context.getType(str);
        default :
            Context.error("must be type", Context.currentPos());
            null;
        }
        
        var name = registerType(type);
        var complexType = Context.toComplexType(type);
        var infoType:ComplexType = macro : shohei909.typepacker.PortableTypeInfomation<$complexType>;
        
        return {
            expr : ECheckType(macro TypePacker.resolveType($v{name}), infoType),
            pos : pos,
        }
    }
    
    public static function resolveType<T>(name:String):PortableTypeInfomation<T> {
        var resource = Resource.getString(getResourceIdentifer(name));
        return Unserializer.run(resource);
    }
    
    private static function getResourceIdentifer(name:String) {
        var str = Type.getClassName(TypePacker) + ":Type:" + name;
        return Base64.encode(Bytes.ofString(str));
    }
    
    #if macro
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
    
    private static function getTypeResolveName(t:MacroType) { 
        return ComplexTypeTools.toString(Context.toComplexType(t));
    }
    
    public static function registerType(type:MacroType) {
        var name = getTypeName(type);
        
        if (isRegistered(name)) return name;
        registered[name] = true;
        
        var t = type, prevT = null;
        var nullable = false;
        
        do {
            if (isNullType(t)) {
                nullable = true;
            }
            prevT = t;
            t = Context.follow(t, true);
        } while (getTypeName(prevT) != getTypeName(t));
        
        var info = switch (t) {
            case TInst(_.toString() => "Array", [element]):
                PortableTypeInfomation.ARRAY(registerType(element));
                
            case TAbstract(_.toString() => "Map", [TInst(_.toString() => "String", []), element]):
                PortableTypeInfomation.STRING_MAP(registerType(element));
                
            case TInst(_.toString() => "String", []) : 
                PortableTypeInfomation.STRING;
                
            case TAbstract(_.toString() => "Float", []) : 
                PortableTypeInfomation.FLOAT(nullable);
                
            case TAbstract(_.toString() => "Bool", []) : 
                PortableTypeInfomation.BOOL(nullable);
                
            case TAbstract(_.toString() => "Int", []) : 
                PortableTypeInfomation.INT(nullable);
                
            case TEnum(ref, []):
                var e = ref.get();
                var map = new Map<String, Array<String>>();
                
                for (key in e.constructs.keys()) {
                    var c = e.constructs.get(key);
                    var arr = [];
                    if (c.meta.has(":nonPacked")) continue;
                    switch(c.type) {
                        case TEnum(_, []):
                        case TFun(args, _):
                            for (a in args) {
                                arr.push(registerType(a.t));
                            };
                        default :
                            Context.error(name + " has unsupported constractor", Context.currentPos());
                    }
                    map[key] = arr;
                }
                PortableTypeInfomation.ENUM(name, map);
                
            case TInst(ref, []) :
                var struct = ref.get();
                if (!struct.meta.has(":packable")) {
                    Context.error(name + " must be @:packable", Context.currentPos());
                }
                
                var map = new Map();
                
                while (true) {
                    mapFields(struct.fields.get(), true, map);
                    if (struct.superClass == null) break;
                    struct = struct.superClass.t.get();
                } 
                
                PortableTypeInfomation.CLASS(name, map);
                
            case TAnonymous(ref):
                var struct = ref.get();
                var map = mapFields(struct.fields, false);
                PortableTypeInfomation.ANONYMOUS(map);
                
            case TAbstract(ref, []) : 
                var abst = ref.get();
                PortableTypeInfomation.ABSTRACT(registerType(abst.type));
                
            default : 
                Context.error("unspported data type " + name, Context.currentPos());
                null;
        };
        
        registerInfomation(name, info);
        return name;
    }
    
    private static function mapFields(fields:Array<haxe.macro.Type.ClassField>, isClass:Bool, map:Map<String, String> = null) {
        if (map == null) map = new Map();
        
        for (f in fields) {
            if (isClass && !f.meta.has(":packed")) continue;
            if (!isClass && f.meta.has(":nonPacked")) continue;
            switch (f.kind) {
                case FMethod(_):
                    continue;
                default:
            }
            
            map[f.name] = registerType(f.type);
        }
        
        return map;
    }
    
    private static var registered:Map<String, Bool> = new Map();
    
    private static function registerInfomation(name:String, data:Dynamic) {
        var str = Serializer.run(data);
        var bytes = Bytes.ofString(str);
        registered[name] = true;
        Context.addResource(getResourceIdentifer(name), bytes);
    }
    
    private static function isRegistered(name:String) {
        return registered.exists(name);
    }
    #end
}
