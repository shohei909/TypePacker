package shohei909.typepacker.cases;
import shohei909.typepacker.BaseTestCase;
import shohei909.typepacker.cases.sample.Sample.SampleAbstract;
import shohei909.typepacker.cases.sample.Sample.SampleClass;
import shohei909.typepacker.cases.sample.Sample.SampleEnum;
import shohei909.typepacker.core.PackerTools;
import shohei909.typepacker.JsonPacker;
/**
 * ...
 * @author shohei909
 */
class JsonPackerTestCase extends BaseTestCase
{
    public var packer:JsonPacker;

    public function new()
    {
        super();
        packer = new JsonPacker();
    }

    public function testPrint() {
        assertEquals("1", packer.print(Int, 1));
        assertEquals("1.1", packer.print(Float, 1.1));
        assertEquals("1", packer.print(Float, 1.0));
        assertEquals("\"サンプル入力\"", packer.print(String, "サンプル入力"));
        assertEquals("null", packer.print(Empty, null));
        assertEquals("{}", packer.print(Empty, { } ));
        assertEquals("[null,{}]", packer.print(ArrayEmpty, [null, { } ]));
        assertEquals("{\"i\":-12}", packer.print(IntData, { i : -12 } ));
        assertEquals("{\"i\":50}", packer.print(IntData, new SampleClass()));
        assertEquals("[\"NONE\"]", packer.print(SampleAbstract, new SampleAbstract(SampleEnum.NONE)));
    }

    public function testParse() {
        assertEquals(1, packer.parse(Int, "1"));
        assertEquals(1.0, packer.parse(Float, "1"));
        assertEquals(-2.1, packer.parse(Float, "-2.1"));
        assertEquals("\"", packer.parse(String, "\"\\\"\""));
        assertEquals(null, packer.parse(Empty, "null"));

        var cl = packer.parse(SampleClass, "{\"i\":50}");
        assertTrue(Std.is(cl, SampleClass));
        assertEquals(50, cl.i);
        assertEquals(null, cl.str);

        var data = packer.parse(IntData, "{\"i\":-12}");
        assertEquals(-12, data.i);

        assertEquals(SampleEnum.NONE, packer.parse(SampleEnum, "[\"NONE\"]"));

        var abst = packer.parse(SampleAbstract, "[\"NONE\"]");
        assertEquals("NONE", abst.name());
    }
}

typedef Empty = {};
typedef ArrayEmpty = Array<Empty>;
typedef IntData = { i : Int };
