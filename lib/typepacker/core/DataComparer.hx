package typepacker.core;
import haxe.DynamicAccess;
import haxe.ds.Vector;
import haxe.io.Bytes;
import typepacker.core.TypeInformation.CollectionType;

class DataComparer
{
	private var setting:CompareSetting;
    public static var defaultSetting(default, null):CompareSetting = new CompareSetting();
	
	public inline function new(setting:CompareSetting)
	{
		this.setting = setting;
	}
	
	public function compare<T>(
		typeInfo:TypeInformation<T>, 
		a:T, 
		b:T, 
		callsFromCompareFunc:Bool = false):Int
	{
		if (a == b) return 0;
		if (a == null) { return if (setting.isNullLast)  1 else -1; }
		if (b == null) { return if (setting.isNullLast) -1 else  1; }
		return switch(typeInfo) {
            case 
				TypeInformation.PRIMITIVE(_) |
				TypeInformation.STRING      :
				Reflect.compare(a, b);
			case
				TypeInformation.CLASS_TYPE   |
				TypeInformation.ENUM_TYPE: 
				Reflect.compare(Std.string(a), Std.string(b));
				
            case TypeInformation.BYTES:
                compareBytes(a, b);
				
            case TypeInformation.ENUM(_, _enum, keys, constractors, _, _):
                compareEnum(_enum, keys, constractors, a, b);
				
            case TypeInformation.CLASS(_, _, fields, fieldNames, _, _, _, _, hasIsCompare):
				compareClass(fields, fieldNames, a, b, hasIsCompare, callsFromCompareFunc);
				
			case TypeInformation.ANONYMOUS(fields, fieldNames, _, _):
                compareAnonymus(fields, fieldNames, a, b);
				
            case TypeInformation.MAP(_, value) :
    			throw "comparing map is not supported";
				
            case TypeInformation.DYNAMIC_ACCESS(value) :
    			throw "comparing dynamic access is not supported";
				
            case TypeInformation.COLLECTION(elementType, type) :
                compareCollection(elementType, type, a, b);
				
            case TypeInformation.ABSTRACT(type) :
                compareAbstract(type, a, b);
        }
	}
	
    private function compareBytes(a:Dynamic, b:Dynamic):Int 
	{
		var a:Bytes = a;
		var b:Bytes = b;
		if (a.getData() == b.getData()) return 0;
		var length = if (a.length < b.length) a.length else b.length;
		for (i in 0...length) 
		{
			var value = compareFloat(a.get(i), b.get(i));
			if (value != 0) { return value; }
		}
		return Reflect.compare(a.length, b.length);
    }
    private function compareAbstract(typeString:String, a:Dynamic, b:Dynamic):Int
	{
        return compare(TypePacker.resolveType(typeString), a, b);
    }
	
    private function compareCollection(elementTypeString:String, type:CollectionType, a:Dynamic, b:Dynamic):Int
	{
		var elementType = TypePacker.resolveType(elementTypeString);
        return switch (type) 
		{
			case ARRAY:
				var a:Array<Dynamic> = a;
				var b:Array<Dynamic> = b;
				var length = if (a.length < b.length) a.length else b.length;
				for (i in 0...length) 
				{
					var value = compare(elementType, a[i], b[i]);
					if (value != 0) { return value; }
				}
				compareFloat(a.length, b.length);
				
			case LIST:
				var a:List<Dynamic> = a;
				var b:List<Dynamic> = b;
				var bi = b.iterator();
				for (ae in a) 
				{
					var be = bi.next();
					if (be == null) break;
					var value = compare(elementType, ae, be);
					if (value != 0) { return value; }
				}
				compareFloat(a.length, b.length);
				
			case VECTOR:
				var a:Vector<Dynamic> = a;
				var b:Vector<Dynamic> = b;
				var length = if (a.length < b.length) a.length else b.length;
				for (i in 0...length) 
				{
					var value = compare(elementType, a[i], b[i]);
					if (value != 0) { return value; }
				}
				compareFloat(a.length, b.length);
        }
    }

    private function compareEnum(_enum:Enum<Dynamic>, keys:Map<String, Int>, constractors:Map<Int,Array<String>>, a:Dynamic, b:Dynamic):Int
	{
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
		if (setting.enumAsString)
		{
			var aName:String = Type.enumConstructor(a);
			var bName:String = Type.enumConstructor(b);
			var value = Reflect.compare(aName, bName);
			if (value != 0) { return value; }
		}
		else
		{
			var value = compareFloat(aIndex, bIndex);
			if (value != 0) { return value; }
		}
        var paramTypes = constractors[aIndex];
        var aParams = Type.enumParameters(a);
        var bParams = Type.enumParameters(b);
		for (i in 0...paramTypes.length) 
		{
			var value = compare(TypePacker.resolveType(paramTypes[i]), aParams[i], bParams[i]);
            if (value != 0) { return value; }
        }
        return 0;
    }
	
	private inline function compareFloat(a:Float, b:Float):Int 
	{
		return if (a < b) -1 else if (a == b) 0 else 1;
	}

	private function compareClass(
		fields:Map<String,String>, 
		fieldNames:Array<String>, 
		a:Dynamic,
		b:Dynamic,
		hasIsSame:Bool,
		callsFromIsSameFunc:Bool):Dynamic 
	{
		if (
			hasIsSame &&
			!callsFromIsSameFunc &&
			setting.usesExistingImpl)
		{
			return Reflect.callMethod(a, Reflect.field(a, "compare"), [b]);
		}
		return compareClassFields(fields, fieldNames, a, b);
	}
	private function compareAnonymus(fields:Map<String,String>, fieldNames:Array<String>, a:Dynamic, b:Dynamic):Int
	{
		return compareClassFields(fields, fieldNames, a, b);
	}
	
    private function compareClassFields(fields:Map<String,String>, fieldNames:Array<String>, a:Dynamic, b:Dynamic):Int
	{
		for (key in fieldNames) 
		{
			var af = if (!Reflect.hasField(a, key)) { null; } else { Reflect.field(a, key); }
			var bf = if (!Reflect.hasField(b, key)) { null; } else { Reflect.field(b, key); }
			var value = compare(TypePacker.resolveType(fields[key]), af, bf);			
			if (value != 0) { return value; }
		}
		return 0;
	}
}
