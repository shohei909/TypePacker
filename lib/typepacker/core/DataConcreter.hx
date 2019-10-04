package typepacker.core;
import haxe.ds.Vector;
import typepacker.core.PackerBase;
import typepacker.core.PackerSetting;
import typepacker.core.TypeInfomation;

/**
 * ...
 * @author shohei909
 */
class DataConcreter {
    var setting:PackerSetting;

    public function new(setting:PackerSetting) {
        this.setting = setting;
    }

    public function concrete<T>(typeInfo:TypeInfomation<T>, data:Dynamic):T {
        return switch(typeInfo) {
            case TypeInfomation.PRIMITIVE(nullable, type) :
                if ((setting.forceNullable || nullable) && (data == null)) {
                    null;
                } else {
                    constructPrimitive(type, data);
                }
            case TypeInfomation.STRING :
                if (data == null) {
                    data;
                } else if (Std.is(data, String)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String");
                }
            case TypeInfomation.ENUM(name, constractors, _):
                (concreteEnum(name, constractors, data) : Dynamic);
            case TypeInfomation.CLASS(name, fields, _) :
                (concreteClass(name, fields, data) : Dynamic);
            case ANONYMOUS(fields, _) :
                (concreteAnonymous(fields, data) : Dynamic);
            case TypeInfomation.MAP(INT, value) :
                (concreteIntMap(value, data) : Dynamic);
            case TypeInfomation.MAP(STRING, value) :
                (concreteStringMap(value, data) : Dynamic);
            case TypeInfomation.COLLECTION(element, ARRAY) :
                (concreteArray(element, data) : Dynamic);
            case TypeInfomation.COLLECTION(element, VECTOR) :
                (concreteVector(element, data) : Dynamic);
            case TypeInfomation.COLLECTION(element, LIST) :
                (concreteList(element, data) : Dynamic);
            case TypeInfomation.ABSTRACT(type) :
                (concreteAbstract(type, data) : Dynamic);
        }
    }


    private function constructPrimitive(type:PrimitiveType, data:Dynamic):Dynamic {
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
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be " + t + " but " + data);
        }
    }

    private function concreteAbstract(typeString:String, data:Dynamic) {
        if (data == null) return null;
        var type = TypePacker.resolveType(typeString);
        return concrete(type, data);
    }


    private function concreteArray<T>(elementTypeString:String, data:Array<T>):Array<T> {
        if (data == null) return null;
        if (!Std.is(data, Array)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
        }

        var elementType = TypePacker.resolveType(elementTypeString);
        var result = [];
        for (element in data) {
            result.push(concrete(elementType, element));
        }

        return result;
    }

    private function concreteVector<T>(elementTypeString:String, data:Array<T>):Vector<T> {
        if (data == null) return null;

        #if (cs || java)
        throw "concrete Vector is not supported in this platform";
        return null;
        #else
        return Vector.fromArrayCopy(concreteArray(elementTypeString, data));
        #end
    }

    private function concreteList<T>(elementTypeString:String, data:Array<T>):List<T> {
        if (data == null) return null;
        return Lambda.list(concreteArray(elementTypeString, data));
    }

    private function concreteEnum(enumName:String, constractors:Map<String,Array<String>>, data:Dynamic):EnumValue {
        if (data == null) return null;
        if (!Std.is(data, Array)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
        }

        var array:Array<Dynamic> = data;
        if (!Std.is(array[0], String)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be string");
        }

        var c:String = array[0];
        var paramTypes = constractors[c];
        var params = [];
        var e = Type.resolveEnum(enumName);

        for (i in 0...paramTypes.length) {
            var type = TypePacker.resolveType(paramTypes[i]);
            params.push(concrete(type, array[i + 1]));
        }

        return Type.createEnum(e, c, params);
    }

    private function concreteClass(className:String, fields:Map<String,String>, data:Dynamic):Dynamic {
        if (data == null) return null;
        var result = Type.createEmptyInstance(Type.resolveClass(className));
        for (key in fields.keys()) {
            var type = TypePacker.resolveType(fields[key]);
            var f = if (!Reflect.hasField(data, key)) {
                null;
            } else {
                Reflect.field(data, key);
            }

            var value = concrete(type, f);
            Reflect.setField(result, key, value);
        }
        return result;
    }

    private function concreteAnonymous(fields:Map<String,String>, data:Dynamic):Dynamic {
        if (data == null) return null;
        var result = {};
        for (key in fields.keys()) {
            var type = TypePacker.resolveType(fields[key]);
            var f = if (!Reflect.hasField(data, key)) {
                null;
            } else {
                Reflect.field(data, key);
            }

            var value = concrete(type, f);
            Reflect.setField(result, key, value);
        }
        return result;
    }

    private function concreteStringMap(valueType:String, data:Dynamic) {
        if (data == null) return null;

        var result:Map<String, Dynamic> = new Map();
        var type = TypePacker.resolveType(valueType);

        for (key in Reflect.fields(data)) {
            result[key] = concrete(type, Reflect.field(data, key));
        }

        return result;
    }

    private function concreteIntMap(valueType:String, data:Dynamic) {
        if (data == null) return null;

        var result:Map<Int, Dynamic> = new Map();
        var type = TypePacker.resolveType(valueType);

        for (key in Reflect.fields(data)) {
            var i = Std.parseInt(key);
            if (i == null) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be int");
            } else {
                result[i] = concrete(type, Reflect.field(data, key));
            }
        }

        return result;
    }
}
