package typepacker.core;
import haxe.DynamicAccess;
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
                if ((setting.forceNullable || nullable) && (data == null)) {
                    data;
                } else {
                    simplifyPrimitive(type, data);
                }
            case TypeInformation.STRING :
                if (data == null) {
                    data;
                } else if (Std.isOfType(data, String)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String : actual " + data);
                }
            case TypeInformation.CLASS_TYPE:
                if (data == null) {
                    null;
                } else if (Std.isOfType(data, Class)) {
                    (Type.getClassName((data:Dynamic)) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Class<T> : actual " + data);
                }
            case TypeInformation.ENUM_TYPE:
                if (data == null) {
                    null;
                } else if (Std.isOfType(data, Enum)) {
                    (Type.getEnumName((data:Dynamic)) : Dynamic);
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Enum<T> : actual " + data);
                }
            case TypeInformation.BYTES:
                (simplifyBytes(data) : Dynamic);
            case TypeInformation.ENUM(_, _, keys, constractors, nameToAlias, aliasToName):
                (simplifyEnum(keys, constractors, data, nameToAlias) : Dynamic);
            case TypeInformation.CLASS(_, _, fields, fieldNames, nameToAlias, serializeToArray, _) | 
			     TypeInformation.ANONYMOUS(fields, fieldNames, nameToAlias, serializeToArray) :
                (simplifyClassInstance(fields, fieldNames, data, nameToAlias, serializeToArray) : Dynamic);
            case TypeInformation.MAP(STRING, value) :
                (simplifyStringMap(value, (data:Dynamic)) : Dynamic);
            case TypeInformation.MAP(INT, value) :
                (simplifyIntMap(value, (data:Dynamic)) : Dynamic);
            case TypeInformation.DYNAMIC_ACCESS(value) :
                (simplifyDynamicAccess(value, (data:Dynamic)) : Dynamic);
            case TypeInformation.COLLECTION(elementType, type) :
                (simplifyCollection(elementType, type, data) : Dynamic);
            case TypeInformation.ABSTRACT(type) :
                (simplifyAbstract(type, data) : Dynamic);
        }
    }

    private function simplifyPrimitive(type:PrimitiveType, data:Dynamic):Dynamic {
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
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be " + type + " : actual " + data);
        }
    }
    private function simplifyBytes(data:Dynamic):Dynamic {
        return if (data == null) {
            data;
        } else if (Std.isOfType(data, Bytes)) {
            if (setting.bytesToBase64) {
                if (base64 == null) base64 = new BaseCode(Base64.BYTES);
                base64.encodeBytes(data).toString();
            } else {
                data;
            }
        } else {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Bytes : actual " + data);
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

    private function simplifyEnum(keys:Map<String, Int>, constractors:Map<Int,Array<String>>, data:Dynamic, nameToAlias:Null<Map<String, String>>):Dynamic
	{
        if (data == null) return null;
        if (setting.validates && !Reflect.isEnumValue(data)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be enum : actual " + data);
        }

		var result:Array<Dynamic> = null;
		var header:Dynamic;
		inline function add(data:Dynamic):Void
		{
			if (result == null) { result = [header]; }
			result.push(data);
		}
		
		var index:Int;
		if (setting.useEnumIndex)
		{
			index = Type.enumIndex(data);
			header = index;
		}
		else
		{
			var c = Type.enumConstructor(data);
			index = keys[c];
			if (nameToAlias != null && nameToAlias.exists(c)) 
			{
				c = nameToAlias[c];
			}
			header = c;
		}
		if (setting.forcesEnumToArray) { result = [header]; }
		
		var paramTypes = constractors[index];
		var params = Type.enumParameters(data);
		var nullCount = 0;
		for (i in 0...paramTypes.length) 
		{
			var type = TypePacker.resolveType(paramTypes[i]);
			var data = simplify(type, params[i]);
			if (data == null) 
			{
				nullCount += 1;
			}
			else
			{
				for (_ in 0...nullCount)
				{
					add(null);
				}
				nullCount = 0;
				add(data);
			}
		}
		if (!setting.omitsNull)
		{
			for (_ in 0...nullCount)
			{
				add(null);
			}
			nullCount = 0;
		}
        return if (result == null) { header; } else { result; }
    }

    private function simplifyClassInstance(fields:Map<String,String>, fieldNames:Array<String>, data:Dynamic, nameToAlias:Null<Map<String, String>>, serializeToArray:Bool):Dynamic {
        if (data == null) return null;
		if (serializeToArray)
		{
			var array = [];
			for (key in fieldNames)
			{
				var type = TypePacker.resolveType(fields[key]);
				var f = if (!Reflect.hasField(data, key)) {
					null; 
				} else {
					Reflect.field(data, key);
				}
				array.push(simplify(type, f));
			}
			return array;
		}
		else
		{
			var result = {};
			for (key in fieldNames) {
				var type = TypePacker.resolveType(fields[key]);
				var f = if (!Reflect.hasField(data, key)) {
					null;
				} else {
					Reflect.field(data, key);
				}
				if (nameToAlias != null && nameToAlias.exists(key)) 
				{
					key = nameToAlias[key];
				}
				var value = simplify(type, f);
				if (!setting.omitsNull || value != null)
				{
					Reflect.setField(result, key, value);
				}
			}
			return result;
		}
    }

    private function simplifyStringMap(valueType:String, data:Map<String, Dynamic>):Dynamic {
        if (data == null) return null;
        var result = { };
        var type = TypePacker.resolveType(valueType);

        for (key in data.keys()) {
            if (!Std.isOfType(key, String)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be String : actual " + key);
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
            if (!Std.isOfType(key, Int)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be Int : actual " + key);
            }

            var value = simplify(type, data.get(key));
            Reflect.setField(result, Std.string(key), value);
        }

        return result;
    }

    private function simplifyDynamicAccess(valueType:String, data:DynamicAccess<Dynamic>):Dynamic {
        if (data == null) return null;
        var result = { };
        var type = TypePacker.resolveType(valueType);

        for (key in data.keys()) {
            var value = simplify(type, data.get(key));
            Reflect.setField(result, key, value);
        }
        return result;
    }
}
