package typepacker.core;
import haxe.ds.Vector;
import typepacker.core.PackerBase;
import typepacker.core.PackerSetting;
import typepacker.core.TypeInformation;

/**
 * ...
 * @author shohei909
 */
class DataConcreter {
    var setting:PackerSetting;

    public function new(setting:PackerSetting) {
        this.setting = setting;
    }

    public function concrete<T>(typeInfo:TypeInformation<T>, data:Dynamic):T {
        return switch(typeInfo) {
            case TypeInformation.PRIMITIVE(nullable, type) :
                if ((setting.forceNullable || nullable) && (data == null)) {
                    null;
                } else {
                    constructPrimitive(type, data);
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
                } else if (Std.is(data, String)) {
                    (Type.resolveClass(data) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Class<T>");
                }
            case TypeInformation.ENUM_TYPE:
                if (data == null) {
                    null;
                } else if (Std.is(data, String)) {
                    (Type.resolveEnum(data) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be ENUM<T>");
                }
            case TypeInformation.ENUM(name, _enum, keys, constractors):
                (concreteEnum(name, _enum, keys, constractors, data) : Dynamic);
            case TypeInformation.CLASS(name, _class, fields, _) :
                (concreteClass(name, _class, fields, data) : Dynamic);
            case ANONYMOUS(fields, _) :
                (concreteAnonymous(fields, data) : Dynamic);
            case TypeInformation.MAP(INT, value) :
                (concreteIntMap(value, data) : Dynamic);
            case TypeInformation.MAP(STRING, value) :
                (concreteStringMap(value, data) : Dynamic);
            case TypeInformation.COLLECTION(element, ARRAY) :
                (concreteArray(element, data) : Dynamic);
            case TypeInformation.COLLECTION(element, VECTOR) :
                (concreteVector(element, data) : Dynamic);
            case TypeInformation.COLLECTION(element, LIST) :
                (concreteList(element, data) : Dynamic);
            case TypeInformation.ABSTRACT(type) :
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

    private function concreteEnum(name:String, _enum:Enum<Dynamic>, keys:Map<String, Int>, constractors:Map<Int, Array<String>>, data:Dynamic):EnumValue {
        if (data == null) return null;
        if (_enum == null) _enum = Type.resolveEnum(name);
        if (!Std.is(data, Array)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
        }

        var array:Array<Dynamic> = data;
        var index:Int;
        if (setting.useEnumIndex)
        {
            if (!Std.is(array[0], Int)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be int");
            }
            index = array[0];
        }
        else
        {
            if (!Std.is(array[0], String)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be string");
            }
            var c:String = array[0];
            index = keys[c];
        }
        var paramTypes = constractors[index];
        var params = [];

        for (i in 0...paramTypes.length) {
            var type = TypePacker.resolveType(paramTypes[i]);
            params.push(concrete(type, array[i + 1]));
        }

        return Type.createEnumIndex(_enum, index, params);
    }

    private function concreteClass(name:String, _class:Class<Dynamic>, fields:Map<String,String>, data:Dynamic):Dynamic {
        if (data == null) return null;
        if (_class == null) _class = Type.resolveClass(name);
        var result = Type.createEmptyInstance(_class);
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
