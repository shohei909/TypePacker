package typepacker.core;
import haxe.DynamicAccess;
import haxe.crypto.Base64;
import haxe.crypto.BaseCode;
import haxe.ds.Vector;
import haxe.io.Bytes;
import typepacker.core.PackerBase;
import typepacker.core.PackerSetting;
import typepacker.core.TypeInformation;

/**
 * ...
 * @author shohei909
 */
class DataConcreter {
    var setting:PackerSetting;
    private static var base64:BaseCode;
    
    public function new(setting:PackerSetting) {
        this.setting = setting;
    }

    public function concrete<T>(typeInfo:TypeInformation<T>, data:Dynamic):T {
        return switch(typeInfo) {
            case TypeInformation.PRIMITIVE(nullable, type) :
                switch (type)
                {
                    case PrimitiveType.INT   if (!nullable && setting.initializesWithZero  && data == null) : cast 0;
                    case PrimitiveType.FLOAT if (!nullable && setting.initializesWithZero  && data == null) : cast 0.0;
                    case PrimitiveType.BOOL  if (!nullable && setting.initializesWithFalse && data == null) : cast false;
                    case _: 
                        if ((setting.forceNullable || nullable) && (data == null)) {
                            null;
                        } else {
                            constructPrimitive(type, data);
                        }
                }
                
            case TypeInformation.STRING :
                if (data == null) {
                    data;
                } else if (Std.isOfType(data, String)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String");
                }
            case TypeInformation.CLASS_TYPE:
                if (data == null) {
                    null;
                } else if (Std.isOfType(data, String)) {
                    (Type.resolveClass(data) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Class<T>");
                }
            case TypeInformation.ENUM_TYPE:
                if (data == null) {
                    null;
                } else if (Std.isOfType(data, String)) {
                    (Type.resolveEnum(data) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be ENUM<T>");
                }
            case TypeInformation.BYTES:
                (concreteBytes(data) : Dynamic);
            case TypeInformation.ENUM(name, _enum, keys, constractors, nameToAlias, aliasToName):
                (concreteEnum(name, _enum, keys, constractors, data, aliasToName) : Dynamic);
            case TypeInformation.CLASS(name, _class, fieldTypes, fieldNames, nameToAlias, serializeToArray, _) :
                (concreteClass(name, _class, fieldTypes, fieldNames, data, nameToAlias, serializeToArray) : Dynamic);
            case TypeInformation.ANONYMOUS(fieldTypes, fieldNames, nameToAlias, serializeToArray) :
                (concreteAnonymous(fieldTypes, fieldNames, data, nameToAlias, serializeToArray) : Dynamic);
            case TypeInformation.MAP(INT, value) :
                (concreteIntMap(value, data) : Dynamic);
            case TypeInformation.MAP(STRING, value) :
                (concreteStringMap(value, data) : Dynamic);
            case TypeInformation.DYNAMIC_ACCESS(value) :
                (concreteDynamicAccess(value, data) : Dynamic);
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
                if (setting.intAsFloat) Float else Int;
            case PrimitiveType.BOOL:
                Bool;
            case PrimitiveType.FLOAT:
                Float;
        }

        return if (Std.isOfType(data, t)) {
            data;
        } else {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be " + t + " but " + data);
        }
    }
    private function concreteBytes(data:Dynamic):Dynamic {
        return if (data == null) {
            null;
        } else if (Std.isOfType(data, Bytes)) {
            data;
        } else {
            if (setting.bytesToBase64) {
                if (Std.isOfType(data, String)) {
                    if (base64 == null) base64 = new BaseCode(Base64.BYTES);
                    base64.decodeBytes(Bytes.ofString(data));
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Bytes or String");
                }
            } else {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Bytes");
            }
        }
    }
    private function concreteAbstract(typeString:String, data:Dynamic) {
        if (data == null) return null;
        var type = TypePacker.resolveType(typeString);
        return concrete(type, data);
    }


    private function concreteArray<T>(elementTypeString:String, data:Array<T>):Array<T> {
        if (data == null) {
			return if (setting.initializesWithEmptyArray) [] else null;
		}
        if (!Std.isOfType(data, Array)) {
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
		if (data == null) {
			return if (setting.initializesWithEmptyVector) new Vector(0) else null;
		}
        #if (cs || java)
        throw "concrete Vector is not supported in this platform";
        return null;
        #else
        return Vector.fromArrayCopy(concreteArray(elementTypeString, data));
        #end
    }

    private function concreteList<T>(elementTypeString:String, data:Array<T>):List<T> {
        if (data == null) {
			return if (setting.initializesWithEmptyList) new List() else null;
		}
        return Lambda.list(concreteArray(elementTypeString, data));
    }

    private function concreteEnum(name:String, _enum:Enum<Dynamic>, keys:Map<String, Int>, constractors:Map<Int, Array<String>>, data:Dynamic, aliasToName:Null<Map<String, String>>):EnumValue {
        if (data == null) return null;
        if (_enum == null) _enum = Type.resolveEnum(name);

		var index:Int;
		var array:Array<Dynamic> = null;
		var value:Dynamic;
		if (Std.isOfType(data, Array))
		{
			array = data;
			value = array[0];
		}
		else
		{
			value = data;
		}
		if (Std.isOfType(value, Int)) 
		{
			index = value;
		}
		else if (Std.isOfType(value, String))
		{
			var c:String = value;
			if (aliasToName != null && aliasToName.exists(c))
			{
				c = aliasToName[c];
			}
			index = keys[c];
		}
		else
		{
			throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array, int or string");
		}
		var paramTypes = constractors[index];
		var params = null;
		if (paramTypes.length > 0)
		{
			params = [];
			if (array == null)
			{
				for (i in 0...paramTypes.length) 
				{
					var type = TypePacker.resolveType(paramTypes[i]);
					params.push(concrete(type, null));
				}
			}
			else
			{
				for (i in 0...paramTypes.length) 
				{
					var type = TypePacker.resolveType(paramTypes[i]);
					params.push(concrete(type, array[i + 1]));
				}
			}
		}
        return Type.createEnumIndex(_enum, index, params);
    }

    private function concreteClass(name:String, _class:Class<Dynamic>, fields:Map<String,String>, fieldNames:Array<String>, data:Dynamic, nameToAlias:Null<Map<String, String>>, serializeToArray:Bool):Dynamic {
        if (data == null) return null;
        if (_class == null) _class = Type.resolveClass(name);
        
		var result = Type.createEmptyInstance(_class);
		setFields(result, fields, fieldNames, data, nameToAlias, serializeToArray);
		return result;
    }

    private function concreteAnonymous(fields:Map<String,String>, fieldNames:Array<String>, data:Dynamic, nameToAlias:Null<Map<String, String>>, serializeToArray:Bool):Dynamic {
        if (data == null) {
			return if (setting.initializesWithEmptyAnonymous) {} else null;
		}
		var result = {};
		setFields(result, fields, fieldNames, data, nameToAlias, serializeToArray);
		return result;
    }
	
	private function setFields(result:Dynamic, fields:Map<String,String>, fieldNames:Array<String>, data:Dynamic, nameToAlias:Null<Map<String, String>>, serializeToArray:Bool):Void
	{
		if (serializeToArray)
		{
			if (!Std.isOfType(data, Array)) throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Array (because @:serializeToArray)");
			var array:Array<Dynamic> = cast data;
			if (array.length < fieldNames.length) throw new TypePackerError(TypePackerError.FAIL_TO_READ, "not enough fields");
			for (i in 0...fieldNames.length) 
			{
				var key = fieldNames[i];
				var type = TypePacker.resolveType(fields[key]);
				var f = array[i];
				var value = concrete(type, f);
				Reflect.setField(result, key, value);
			}
		}
		else
		{
			for (key in fieldNames) 
			{
				var type = TypePacker.resolveType(fields[key]);
				var f = if (!Reflect.hasField(data, key)) {
					if (nameToAlias == null || !nameToAlias.exists(key)) {
						null; 
					} else {
						var alias = nameToAlias[key];
						if (!Reflect.hasField(data, alias)) {
							null;
						} else {
							Reflect.field(data, alias);
						}
					}
				} else {
					Reflect.field(data, key);
				}
				var value = concrete(type, f);
				Reflect.setField(result, key, value);
			}
		}
	}

    private function concreteStringMap(valueType:String, data:Dynamic) {
        if (data == null) {
			return if (setting.initializesWithEmptyMap) new Map() else null;
		}
        var result:Map<String, Dynamic> = new Map();
        var type = TypePacker.resolveType(valueType);

        for (key in Reflect.fields(data)) {
            result[key] = concrete(type, Reflect.field(data, key));
        }

        return result;
    }
    private function concreteDynamicAccess(valueType:String, data:Dynamic):DynamicAccess<Dynamic> {
        if (data == null) {
			return if (setting.initializesWithEmptyDynamicAccess) {} else null;
		}
        var result:DynamicAccess<Dynamic> = {};
        var type = TypePacker.resolveType(valueType);

        for (key in Reflect.fields(data)) {
            result[key] = concrete(type, Reflect.field(data, key));
        }

        return result;
    }

    private function concreteIntMap(valueType:String, data:Dynamic) {
        if (data == null) {
			return if (setting.initializesWithEmptyMap) new Map() else null;
		}
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
