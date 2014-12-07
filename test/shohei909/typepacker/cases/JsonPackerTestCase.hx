package shohei909.typepacker.cases;
import shohei909.typepacker.BaseTestCase;
import shohei909.typepacker.cases.sample.Sample.SampleAbstract;
import shohei909.typepacker.cases.sample.Sample.SampleClass;
import shohei909.typepacker.cases.sample.Sample.SampleEnum;

/**
 * ...
 * @author shohei909
 */
class JsonPackerTestCase extends BaseTestCase
{

	public function new() 
	{
		super();
	}
	
	public function testPrint() {
		assertEquals("1", JsonPacker.print(TypePacker.toTypeInfomation(Int), 1));
		assertEquals("1.1", JsonPacker.print(TypePacker.toTypeInfomation(Float), 1.1));
		assertEquals("1", JsonPacker.print(TypePacker.toTypeInfomation(Float), 1.0));
		assertEquals("\"サンプル入力\"", JsonPacker.print(TypePacker.toTypeInfomation(String), "サンプル入力"));
		assertEquals("null", JsonPacker.print(TypePacker.toTypeInfomation(Empty), null));
		assertEquals("{}", JsonPacker.print(TypePacker.toTypeInfomation(Empty), { } ));
		assertEquals("[null,{}]", JsonPacker.print(TypePacker.toTypeInfomation(ArrayEmpty), [null, { } ]));
		assertEquals("{\"i\":-12}", JsonPacker.print(TypePacker.toTypeInfomation(IntData), { i : -12 } ));
		assertEquals("{\"i\":50}", JsonPacker.print(TypePacker.toTypeInfomation(IntData), new SampleClass()));
		assertEquals("[\"NONE\"]", JsonPacker.print(TypePacker.toTypeInfomation(SampleAbstract), new SampleAbstract(SampleEnum.NONE)));
	}
	
	public function testParse() {
		assertEquals(1, JsonPacker.parse(TypePacker.toTypeInfomation(Int), "1"));
		assertEquals(1.0, JsonPacker.parse(TypePacker.toTypeInfomation(Float), "1"));
		assertEquals(-2.1, JsonPacker.parse(TypePacker.toTypeInfomation(Float), "-2.1"));
		assertEquals("\"", JsonPacker.parse(TypePacker.toTypeInfomation(String), "\"\\\"\""));
		assertEquals(null, JsonPacker.parse(TypePacker.toTypeInfomation(Empty), "null"));
		
		var cl = JsonPacker.parse(TypePacker.toTypeInfomation(SampleClass), "{\"i\":50}");
		assertTrue(Std.is(cl, SampleClass));
		assertEquals(50, cl.i);
		assertEquals(null, cl.str);
		
		var data = JsonPacker.parse(TypePacker.toTypeInfomation(IntData), "{\"i\":-12}");
		assertEquals(-12, data.i);
		
		assertEquals(SampleEnum.NONE, JsonPacker.parse(TypePacker.toTypeInfomation(SampleEnum), "[\"NONE\"]"));
		
		var abst = JsonPacker.parse(TypePacker.toTypeInfomation(SampleAbstract), "[\"NONE\"]");
		assertEquals("NONE", abst.name());
	}
}

typedef Empty = {};
typedef ArrayEmpty = Array<Empty>;
typedef IntData = { i : Int };