package typepacker.core;
import haxe.crypto.Base64;
import haxe.crypto.BaseCode;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.macro.Expr;
import typepacker.core.TypeInformation.CollectionType;
import typepacker.core.TypeInformation.MapKeyType;
import typepacker.core.TypeInformation.PrimitiveType;

/**
 * ...
 * @author shohei909
 */
class DataSimplifier {
    var setting:PackerSetting;
    private static var base64:BaseCode;
    
    public function new(setting:PackerSetting) {
        this.setting = setting;
    }

    public function simplify<T>(typeInfo:TypeInformation<T>, data:T) : Dynamic {
        return switch(typeInfo) {
            case TypeInformation.PRIMITIVE(nullable, type) :
                if (nullable && (data == null)) {
                    data;
                } else {
                    simplifyPrimitive(type, data);
                }
            case TypeInformation.STRING :
                if (data == null) {
                    data;
                } else if (Std.is(data, String)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String");
                }
            case TypeInformation.CLASS_TYPE:
                if (data == null) {
                    null;
                } else if (Std.is(data, Class)) {
                    (Type.getClassName((data:Dynamic)) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Class<T>");
                }
            case TypeInformation.ENUM_TYPE:
                if (data == null) {
                    null;
                } else if (Std.is(data, Enum)) {
                    (Type.getEnumName((data:Dynamic)) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Enum<T>");
                }
            case TypeInformation.BYTES:
                (simplifyBytes(data) : Dynamic);
            case TypeInformation.ENUM(_, _, keys, constractors):
                (simplifyEnum(keys, constractors, data) : Dynamic);
            case TypeInformation.CLASS(_, _, fields, _) | ANONYMOUS(fields, _) :
                (simplifyClassInstance(fields, data) : Dynamic);
            case TypeInformation.MAP(STRING, value) :
                (simplifyStringMap(value, (data:Dynamic)) : Dynamic);
            case TypeInformation.MAP(INT, value) :
                (simplifyIntMap(value, (data:Dynamic)) : Dynamic);
            case TypeInformation.COLLECTION(elementType, type) :
                (simplifyCollection(elementType, type, data) : Dynamic);
            case TypeInformation.ABSTRACT(type) :
                (simplifyAbstract(type, data) : Dynamic);
        }
    }

    private function simplifyPrimitive(type:PrimitiveType, data:Dynamic):Dynamic {
        var t:Dynamic = switch (type) {
            case PrimitiveType.INT:
                Int;
            case PrimitiveType.BOOL:
                Bool;
            case PrimitiveType.FLOAT:
                Float;
        }

        return if (Std.is(data, t)) {
            data;
        } else {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be " + t);
        }
    }
    private function simplifyBytes(data:Dynamic):Dynamic {
        return if (data == null) {
            data;
        } else if (Std.is(data, Bytes)) {
            if (setting.bytesToBase64) {
                if (base64 == null) base64 = new BaseCode(Base64.BYTES);
                base64.encodeBytes(data).toString();
            } else {
                data;
            }
        } else {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Bytes");
        }
    }
    private function simplifyAbstract(typeString:String, data:Dynamic) {
        if (data == null) return null;
        var type = TypePacker.resolveType(typeString);
        return simplify(type, data);
    }

    private function simplifyCollection(elementTypeString:String, type:CollectionType, data:Dynamic):Array<Dynamic> {
        if (data == null) return null;

        var elementType = TypePacker.resolveType(elementTypeString);
        var result:Array<Dynamic> = [];

        switch (type) {
        case ARRAY:
            for (element in (data: Array<Dynamic>)) {
                result.push(simplify(elementType, element));
            }
        case LIST:
            for (element in (data: List<Dynamic>)) {
                result.push(simplify(elementType, element));
            }
        case VECTOR:
            for (element in (data: Vector<Dynamic>)) {
                result.push(simplify(elementType, element));
            }
        }

        return result;
    }

    private function simplifyEnum(keys:Map<String, Int>, constractors:Map<Int,Array<String>>, data:Dynamic) {
        if (data == null) return null;
        if (!setting.validates && !Reflect.isEnumValue(data)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be enum");
        }

        var result:Array<Dynamic> = [];
        var index:Int;
        if (setting.useEnumIndex)
        {
            index = Type.enumIndex(data);
            result.push(index);
        }
        else
        {
            var c = Type.enumConstructor(data);
            result.push(c);
            index = keys[c];
        }
        var paramTypes = constractors[index];
        var params = Type.enumParameters(data);

        for (i in 0...paramTypes.length) {
            var type = TypePacker.resolveType(paramTypes[i]);
            result.push(simplify(type, params[i]));
        }

        return result;
    }

    private function simplifyClassInstance(fields:Map<String,String>, data:Dynamic):Dynamic {
        if (data == null) return null;
        var result = {};
        for (key in fields.keys()) {
            var type = TypePacker.resolveType(fields[key]);
            var f = if (!Reflect.hasField(data, key)) {
                null;
            } else {
                Reflect.field(data, key);
            }

            var value = simplify(type, f);
            Reflect.setField(result, key, value);
        }
        return result;
    }

    private function simplifyStringMap(valueType:String, data:Map<String, Dynamic>):Dynamic {
        if (data == null) return null;
        var result = { };
        var type = TypePacker.resolveType(valueType);

        for (key in data.keys()) {
            if (!Std.is(key, String)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be String");
            }

            var value = simplify(type, data.get(key));
            Reflect.setField(result, key, value);
        }
        return result;
    }

    private function simplifyIntMap(valueType:String, data:Map<Int, Dynamic>):Dynamic {
        if (data == null) return null;
        var result = {};
        var type = TypePacker.resolveType(valueType);

        for (key in data.keys()) {
            if (!Std.is(key, Int)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be Int");
            }

            var value = simplify(type, data.get(key));
            Reflect.setField(result, Std.string(key), value);
        }

        return result;
    }
}
