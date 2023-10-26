# TypePacker

TypePacker provides the following functionality by using type information collected at compile time macro.

* Deep Clone 
* Structural Equality (Deep Equal)
* Serialize / Unserialize


## Deep Clone

```hx
var cloneData = typepacker.core.TypeUtil.clone("Array<Int>", [0, 1, 2]);
```

The `typepacker.core.Clone` interface automatically implements the `clone` function.

```hx
import typepacker.core.Clone;

class SampleData implements Clone
{
	public var a:Int;
	public var b:Float;
	
	public function new()
	{
		this.a = 1.0;
		this.b = 2.0;
	}
}

class Main
{
	public static function main():Void
	{
		var data = new SampleData();
		var cloneData = data.clone();
	}
}
```

Please refer to [the test cases](test/cases/CloneTestCase.hx) for more detailed usage.


## Deep Equal

```hx
import typepacker.core.TypeUtil;

class SampleData
{
	public var a:Int;
	public var b:Float;
	
	public function new()
	{
		this.a = 1.0;
		this.b = 2.0;
	}
}

class Main
{
	public static function main():Void
	{
		var a = new SampleData();
		var b = new SampleData();
		var cloneData = TypeUtil.isSame("SampleData", a, b); // true
	}
}
```

## Serialize / Unserialize


### Json 

```hx
var jsonString = typepacker.json.Json.print("Array<Int>", [0, 1, 2]);
var arrayData = typepacker.json.Json.parse("Array<Int>", jsonString);
```

This serialization method is suited for data persistence.

Please refer to [the test cases](test/cases/JsonPackerTestCase.hx) for more detailed usage.


### TypePacker binary format

```hx
var bytearray = typepacker.bytes.BytesPack.print("Array<Int>", [0, 1, 2]);
var arrayData = typepacker.bytes.BytesPack.parse("Array<Int>", bytearray);
```

This serialization method is suitable for data communications.
It has a smaller data size than Json, but compatibility between versions is more difficult.

Please refer to [the test cases](test/cases/BytesPackerTestCase.hx) for more detailed usage.


### Other formats

Serialization is also possible for any formats compatible with JSON. For example, Message Pack / Yaml.

Please refer to [the Yaml test case](test/cases/YamlPackerTestCase.hx).


# Supported type

Deep Clone / Deep Equal / Serialize / Unserialize is available for the following types.

* Primitive Type(Int / Float / Bool)
* Collection(Array\<T\> / haxe.ds.List\<T\> / haxe.ds.Vector\<T\>)
* String
* Enum
* Anonymous Type
* Abstract
* Typedef
* haxe.io.Bytes
* StringMap / IntMap
* haxe.DynamicAccess\<T\>
* Null\<T\>
* Type (Class\<Dynamic\> / Enum\<Dynamic\>)


## Unsupported

* haxe.ds.EnumMap / haxe.ds.ObjectMap / haxe.ds.WeakMap
* Function Type
* etc...

Recursive types are supported, but instances with circular references are not supported.


# Metadata for fields

* @:serializeAlias(alias)
* @:noPack
