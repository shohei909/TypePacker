package typepacker.core;
import haxe.DynamicAccess;
import haxe.ds.Vector;
import haxe.io.Bytes;
import typepacker.core.TypeInformation.CollectionType;

class DataMatcher
{
	private var setting:IsSameSetting;
    public static var defaultSetting(default, null):IsSameSetting = new IsSameSetting();
	
	public inline function new(setting:IsSameSetting)
	{
		this.setting = setting;
	}
	
	public function isSame<T>(
		typeInfo:TypeInformation<T>, 
		a:T, 
		b:T, 
		callsFromIsSameFunc:Bool = false):Bool
	{
		if (a == b) return true;
		return switch(typeInfo) {
            case 
				TypeInformation.PRIMITIVE(_) |
				TypeInformation.STRING       |
				TypeInformation.CLASS_TYPE   |
				TypeInformation.ENUM_TYPE   : 
				false;
				
            case TypeInformation.BYTES:
                (isSameBytes(a, b) : Dynamic);
				
            case TypeInformation.ENUM(_, _enum, keys, constractors, _, _):
                (isSameEnum(_enum, keys, constractors, a, b) : Dynamic);
				
            case TypeInformation.CLASS(_, _, fields, fieldNames, _, _, _, hasIsSame):
				(isSameClass(fields, fieldNames, a, b, hasIsSame, callsFromIsSameFunc) : Dynamic);
				
			case TypeInformation.ANONYMOUS(fields, fieldNames, _, _):
                (isSameAnonymus(fields, fieldNames, a, b) : Dynamic);
				
            case TypeInformation.MAP(STRING, value) :
                (isSameStringMap(value, (a:Dynamic), (b:Dynamic)) : Dynamic);
				
            case TypeInformation.MAP(INT, value) :
                (isSameIntMap(value, (a:Dynamic), (b:Dynamic)) : Dynamic);
				
            case TypeInformation.DYNAMIC_ACCESS(value) :
                (isSameDynamicAccess(value, (a:Dynamic), (b:Dynamic)) : Dynamic);
				
            case TypeInformation.COLLECTION(elementType, type) :
                (isSameCollection(elementType, type, a, b) : Dynamic);
				
            case TypeInformation.ABSTRACT(type) :
                (isSameAbstract(type, a, b) : Dynamic);
        }
	}
	
    private function isSameBytes(a:Dynamic, b:Dynamic):Bool 
	{
        if (a == null || b == null) return false;
        
		var a:Bytes = a;
		var b:Bytes = b;
		if (a.getData() == b.getData()) return true;
		if (a.length != b.length) return false;
        for (i in 0...a.length)
		{
			if (a.get(i) != b.get(i)) return false;
		}
		return true;
    }
    private function isSameAbstract(typeString:String, a:Dynamic, b:Dynamic):Bool
	{
        if (a == null || b == null) return false;
        return isSame(TypePacker.resolveType(typeString), a, b);
    }
	
    private function isSameCollection(elementTypeString:String, type:CollectionType, a:Dynamic, b:Dynamic):Bool
	{
        if (a == null || b == null) return false;
		var elementType = TypePacker.resolveType(elementTypeString);
        return switch (type) 
		{
			case ARRAY:
				var a:Array<Dynamic> = a;
				var b:Array<Dynamic> = b;
				if (a.length != b.length) return false;
				for (i in 0...a.length) 
				{
					if (!isSame(elementType, a[i], b[i]))
					{
						return false;
					}
				}
				true;
				
			case LIST:
				var a:List<Dynamic> = a;
				var b:List<Dynamic> = b;
				if (a.length != b.length) return false;
				var bi = b.iterator();
				for (ae in a) 
				{
					var be = bi.next();
					if (!isSame(elementType, ae, be))
					{
						return false;
					}
				}
				true;
				
			case VECTOR:
				var a:Vector<Dynamic> = a;
				var b:Vector<Dynamic> = b;
				if (a.length != b.length) return false;
				for (i in 0...a.length) 
				{
					if (!isSame(elementType, a[i], b[i]))
					{
						return false;
					}
				}
				true;
        }
    }

    private function isSameEnum(_enum:Enum<Dynamic>, keys:Map<String, Int>, constractors:Map<Int,Array<String>>, a:Dynamic, b:Dynamic):Bool
	{
        if (a == null || b == null) return false;
		if (setting.validates)
		{
			if (!Reflect.isEnumValue(a)) {
				throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be enum : actual " + a);
			}
			if (!Reflect.isEnumValue(b)) {
				throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be enum : actual " + b);
			}
		}
        var params:Array<Dynamic> = [];
        var aIndex:Int = Type.enumIndex(a);
        var bIndex:Int = Type.enumIndex(b);
		if (aIndex != bIndex)
		{
			return false;
		}
        var paramTypes = constractors[aIndex];
        var aParams = Type.enumParameters(a);
        var bParams = Type.enumParameters(b);
		for (i in 0...paramTypes.length) 
		{
            if (!isSame(TypePacker.resolveType(paramTypes[i]), aParams[i], bParams[i]))
			{
				return false;
			}
        }
        return true;
    }

	private function isSameClass(
		fields:Map<String,String>, 
		fieldNames:Array<String>, 
		a:Dynamic,
		b:Dynamic,
		hasIsSame:Bool,
		callsFromIsSameFunc:Bool):Dynamic 
	{
        if (a == null || b == null) return false;
		if (
			hasIsSame &&
			!callsFromIsSameFunc &&
			setting.usesExistingImpl)
		{
			return Reflect.callMethod(a, Reflect.field(a, "isSame"), [b]);
		}
		return isSameClassFields(fields, fieldNames, a, b);
	}
	private function isSameAnonymus(fields:Map<String,String>, fieldNames:Array<String>, a:Dynamic, b:Dynamic):Bool
	{
        if (a == null || b == null) return false;
		return isSameClassFields(fields, fieldNames, a, b);
	}
	
    private function isSameClassFields(fields:Map<String,String>, fieldNames:Array<String>, a:Dynamic, b:Dynamic):Bool
	{
		for (key in fieldNames) 
		{
			var af = if (!Reflect.hasField(a, key)) { null; } else { Reflect.field(a, key); }
			var bf = if (!Reflect.hasField(b, key)) { null; } else { Reflect.field(b, key); }
			if (!isSame(TypePacker.resolveType(fields[key]), af, bf))
			{
				return false;
			}
		}
		return true;
	}
	

    private function isSameStringMap(valueType:String, a:Map<String, Dynamic>, b:Map<String, Dynamic>):Bool
	{
        if (a == null || b == null) return false;
        var type = TypePacker.resolveType(valueType);
		var aLength = 0;
        for (key in a.keys()) 
		{
            if (setting.validates && !Std.isOfType(key, String)) 
			{
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be String : actual " + key);
            }
			if (!b.exists(key))
			{
				return false;
			}
            if (!isSame(type, a.get(key), b.get(key)))
			{
				return false;
			}
			aLength += 1;
        }
		var bLength = 0;
        for (key in b.keys()) 
		{
			bLength += 1;
		}
		if (aLength != bLength)
		{
			return false;
		}
        return true;
    }

    private function isSameIntMap(valueType:String, a:Map<Int, Dynamic>, b:Map<Int, Dynamic>):Bool
	{
        if (a == null || b == null) return false;
		
		var type = TypePacker.resolveType(valueType);
		var aLength = 0;
        for (key in a.keys()) 
		{
            if (setting.validates && !Std.isOfType(key, Int)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be Int : actual " + key);
            }
			if (!b.exists(key))
			{
				return false;
			}
            if (!isSame(type, a.get(key), b.get(key)))
			{
				return false;
			}
			aLength += 1;
        }
		var bLength = 0;
        for (key in b.keys()) 
		{
			bLength += 1;
		}
		if (aLength != bLength)
		{
			return false;
		}
        return true;
    }

    private function isSameDynamicAccess(valueType:String, a:DynamicAccess<Dynamic>, b:DynamicAccess<Dynamic>):Bool
	{
        if (a == null || b == null) return false;
		
		var type = TypePacker.resolveType(valueType);
		var aLength = 0;
        for (key in a.keys()) 
		{
			if (!b.exists(key))
			{
				return false;
			}
            if (!isSame(type, a.get(key), b.get(key)))
			{
				return false;
			}
			aLength += 1;
        }
		var bLength = 0;
        for (key in b.keys()) 
		{
			bLength += 1;
		}
		if (aLength != bLength)
		{
			return false;
		}
        return true;
    }
}
