package typepacker.core;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import typepacker.core.CloneSetting;
import typepacker.core.TypeInformation.PrimitiveType;
import haxe.DynamicAccess;
import haxe.crypto.Base64;
import haxe.crypto.BaseCode;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.macro.Expr;
import typepacker.core.TypeInformation.CollectionType;
import typepacker.core.TypeInformation.MapKeyType;
import typepacker.core.TypeInformation.PrimitiveType;


class DataCloner
{
	private var setting:CloneSetting;
    public static var defaultSetting(default, null):CloneSetting = new CloneSetting();
	
	public inline function new(setting:CloneSetting)
	{
		this.setting = setting;
	}
	
	public function execute<T>(
		typeInfo:TypeInformation<T>, 
		data:T, 
		callsFromCloneFunc:Bool = false):T
	{
        return switch(typeInfo) {
            case TypeInformation.PRIMITIVE(_): data;
            case TypeInformation.STRING      : data;
            case TypeInformation.CLASS_TYPE  : data;
            case TypeInformation.ENUM_TYPE   : data;
				
            case TypeInformation.BYTES:
                (cloneBytes(data) : Dynamic);
				
            case TypeInformation.ENUM(_, _enum, keys, constractors, _, _):
                (cloneEnum(_enum, keys, constractors, data) : Dynamic);
				
            case TypeInformation.CLASS(_, _class, fields, fieldNames, _, _, hasClone):
				(cloneClass(_class, fields, fieldNames, data, hasClone, callsFromCloneFunc) : Dynamic);
				
			case TypeInformation.ANONYMOUS(fields, fieldNames, _, _):
                (cloneAnonymus(fields, fieldNames, data) : Dynamic);
				
            case TypeInformation.MAP(STRING, value) :
                (cloneStringMap(value, (data:Dynamic)) : Dynamic);
				
            case TypeInformation.MAP(INT, value) :
                (cloneIntMap(value, (data:Dynamic)) : Dynamic);
				
            case TypeInformation.DYNAMIC_ACCESS(value) :
                (cloneDynamicAccess(value, (data:Dynamic)) : Dynamic);
				
            case TypeInformation.COLLECTION(elementType, type) :
                (cloneCollection(elementType, type, data) : Dynamic);
				
            case TypeInformation.ABSTRACT(type) :
                (cloneAbstract(type, data) : Dynamic);
        }
    }

    private function cloneBytes(data:Dynamic):Dynamic {
        return if (data == null) {
            data;
        } else if (Std.isOfType(data, Bytes)) {
			var data:Bytes = data;
			var result = Bytes.alloc(data.length);
            result.blit(0, data, 0, data.length);
			result;
        } else {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Bytes : actual " + data);
        }
    }
    private function cloneAbstract(typeString:String, data:Dynamic) {
        if (data == null) return null;
        return execute(TypePacker.resolveType(typeString), data);
    }
	
    private function cloneCollection(elementTypeString:String, type:CollectionType, data:Dynamic):Dynamic {
        if (data == null) return null;
		
		var elementType = TypePacker.resolveType(elementTypeString);

        return switch (type) 
		{
			case ARRAY:
				var result:Array<Dynamic> = [];
				for (element in (data: Array<Dynamic>)) {
					result.push(execute(elementType, element));
				}
				result;
				
			case LIST:
				var result:List<Dynamic> = new List();
				for (element in (data: List<Dynamic>)) {
					result.add(execute(elementType, element));
				}
				result;
				
			case VECTOR:
				var data:Vector<Dynamic> = data;
				var result:Vector<Dynamic> = new Vector(data.length);
				var i = 0;
				for (element in data) {
					result[i] = execute(elementType, element);
					i += 1;
				}
				result;
        }
    }

    private function cloneEnum(_enum:Enum<Dynamic>, keys:Map<String, Int>, constractors:Map<Int,Array<String>>, data:Dynamic) 
	{
        if (data == null) return null;
        if (setting.validates && !Reflect.isEnumValue(data)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be enum : actual " + data);
        }

        var params:Array<Dynamic> = [];
        var index:Int;
        index = Type.enumIndex(data);
		
        var paramTypes = constractors[index];
        var params = Type.enumParameters(data);
        for (i in 0...paramTypes.length) {
            params.push(execute(TypePacker.resolveType(paramTypes[i]), params[i]));
        }
        return Type.createEnumIndex(
			_enum,
			index,
			params
		);
    }

	private function cloneClass(
		_class:Class<Dynamic>, 
		fields:Map<String,String>, 
		fieldNames:Array<String>, 
		data:Dynamic,
		hasClone:Bool,
		callsFromCloneFunc:Bool):Dynamic 
	{
		if (data == null) return null;
		if (
			hasClone &&
			!callsFromCloneFunc &&
			setting.usesExistingImpl)
		{
			Reflect.callMethod(data, Reflect.field(data, "clone"), []);
		}
		
		var result = Type.createEmptyInstance(_class);
		cloneClassFields(result, fields, fieldNames, data);
		return result;
	}
	private function cloneAnonymus(fields:Map<String,String>, fieldNames:Array<String>, data:Dynamic):Dynamic 
	{
		if (data == null) return null;
		var result = {};
		cloneClassFields(result, fields, fieldNames, data);
		return result;
	}
	
    private function cloneClassFields(result:Dynamic, fields:Map<String,String>, fieldNames:Array<String>, data:Dynamic):Void
	{
		for (key in fieldNames) 
		{
			var f = if (!Reflect.hasField(data, key)) {
				null;
			} else {
				Reflect.field(data, key);
			}
			var value = execute(TypePacker.resolveType(fields[key]), f);
			Reflect.setField(result, key, value);
		}
	}
	

    private function cloneStringMap(valueType:String, data:Map<String, Dynamic>):Dynamic {
        if (data == null) return null;
		
        var result:Map<String, Dynamic> = new Map();
        var type = TypePacker.resolveType(valueType);

        for (key in data.keys()) {
            if (setting.validates && !Std.isOfType(key, String)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be String : actual " + key);
            }
            result[key] = execute(type, data.get(key));
        }
        return result;
    }

    private function cloneIntMap(valueType:String, data:Map<Int, Dynamic>):Dynamic {
        if (data == null) return null;
        
		var result:Map<Int, Dynamic> = new Map();
        var type = TypePacker.resolveType(valueType);

        for (key in data.keys()) {
            if (setting.validates && !Std.isOfType(key, Int)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be Int : actual " + key);
            }
            result[key] = execute(type, data.get(key));
        }

        return result;
    }

    private function cloneDynamicAccess(valueType:String, data:DynamicAccess<Dynamic>):Dynamic {
        if (data == null) return null;
        var result = { };
        var type = TypePacker.resolveType(valueType);

        for (key in data.keys()) {
            var value = execute(type, data.get(key));
            Reflect.setField(result, key, value);
        }
        return result;
    }
}