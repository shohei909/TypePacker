package cases;
import BaseTestCase;
import cases.sample.Sample.SampleAbstract;
import cases.sample.Sample.SampleClass;
import cases.sample.Sample.SampleEnum;
import cases.sample.Sample.SampleStruct;
import haxe.ds.Vector;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import typepacker.bytes.BytesPack;
import typepacker.bytes.BytesPacker;
import typepacker.bytes.BytesUnserialzer;
import typepacker.bytes.BytesSerializer;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;

class BytesPackerTestCase extends BaseTestCase
{
    public function new()
    {
        super();
    }

    public function testIo()
	{
		assertIo(TypePacker.toTypeInformation("Int"), 1);
		assertIo(TypePacker.toTypeInformation("Float"), 3.1);
		assertIo(TypePacker.toTypeInformation("Bool"), false);
		assertIo(TypePacker.toTypeInformation("Null<Int>"), null);
		assertIo(TypePacker.toTypeInformation("Null<Float>"), null);
		assertIo(TypePacker.toTypeInformation("Null<Bool>"), null);
		assertIo(TypePacker.toTypeInformation("String"), "あいうえお");
		assertIo(TypePacker.toTypeInformation("String"), null);
		assertArrayIo(TypePacker.toTypeInformation("Array<Int>"), [0, 0x7FFFFFFF, 0xFFFFFFFF, -1]);
		assertArrayIo(TypePacker.toTypeInformation("Array<Null<Int>>"), [0, 21, null, 4]);
		assertIo(TypePacker.toTypeInformation("Class<SampleClass>"), SampleClass);
		assertIo(TypePacker.toTypeInformation("Enum<SampleEnum>"), SampleEnum);
		{
			#if !static
			var data1:Array<String> = [""];
			var data2:Vector<String> = convert(TypePacker.toTypeInformation("Vector<String>"), Vector.fromArrayCopy(data1));
			assertArrayEquals(data1, data2.toArray());
			#end
		}
		
		{
			var data = convert(TypePacker.toTypeInformation("IntData"), {i: 32});
			assertEquals(32, data.i);
		}
		{
			var data:SampleClass = convert(TypePacker.toTypeInformation("SampleClass"), new SampleClass());
			assertTrue(Std.is(data, SampleClass));
			assertEquals(50, data.i);
			assertEquals(null, data.e);
			assertEquals("hoge", data.str);
			assertNotEquals(null, data.intMap);
			assertArrayEquals([0, 5, 3], Lambda.array(data.intMap[102]));
			assertMapEquals(["test" => 100, "test2" => 101], data.stringMap);
		}
		{
			var data1 = SampleEnum.LINK(SampleEnum.NONE, null);
			var data2 = convert(TypePacker.toTypeInformation("SampleEnum"), data1);
			assertTrue(Type.enumEq(data1, data2));
		}
		{
			var data1 = {
				c: null,  
				e: SampleEnum.LINK(null, null),
				i: SampleEnum.NONE,
			};
			var data2 = convert(TypePacker.toTypeInformation("SampleStruct"), data1);
			assertTrue(Type.enumEq(data1.e, data2.e));
			assertTrue(Type.enumEq(data1.i, data2.i));
		}
		{
			var data1 = convert(TypePacker.toTypeInformation("SampleAbstract"), new SampleAbstract(SampleEnum.NONE));
			assertEquals("NONE", data1.name());
		}
	}
	private function assertIo<T>(info:TypeInformation<T>, value:T):Void
	{
        assertEquals(value, convert(info, value));
	}
	private function assertArrayIo<T>(info:TypeInformation<Array<T>>, value:Array<T>):Void
	{
        assertArrayEquals(value, convert(info, value));
	}
	
	private static function convert<T>(info:TypeInformation<T>, value:T):T
	{
		var bytesOutput = new BytesOutput();
		BytesPack.serializeWithInfo(info, value, bytesOutput);
		var bytesInput = new BytesInput(bytesOutput.getBytes());
		return BytesPack.unserializeWithInfo(info, bytesInput);
	}
}
