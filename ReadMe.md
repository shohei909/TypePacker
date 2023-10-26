# TypePacker

TypePacker provides the following functionality by using type information collected at compile time.

* Deep Clone 
* Deep Equal (Structural Equality)
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

Please refer to [the test cases](test/cases/sample/CloneTestCase.hx) for more detailed usage.


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

Please refer to [the test cases](test/cases/sample/JsonPackerTestCase.hx) for more detailed usage.


### TypePacker binary format

```hx
var bytearray = typepacker.bytes.BytesPack.print("Array<Int>", [0, 1, 2]);
var arrayData = typepacker.bytes.BytesPack.parse("Array<Int>", bytearray);
```

This serialization method is suitable for data communications.
It has a smaller file size than Json, but compatibility between versions is difficult.

Please refer to [the test cases](test/cases/sample/BytesPackerTestCase.hx) for more detailed usage.


### Other format

Serialization is also possible for any format compatible with JSON. For example, Message Pack / Yaml.

Please refer to [the Yaml test case](test/cases/sample/YamlPackerTestCase.hx).


# Supported type

Deep Clone / Deep Equal / Serialize / Unserialize is available for the following types.

* Primitive Type(Int / Float / Bool)
* String
* Enum
* Abstract
* Typedef
* Type (Class<Dynamic> / Enum<Dynamic>)
* Collection
* Bytes
* StringMap / IntMap
* Anonymous Type
* DynamicAccess<T>
* Null<T>
