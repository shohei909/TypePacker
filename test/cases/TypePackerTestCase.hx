package cases;
import nanotest.NanoTestCase;
import cases.sample.Sample.SampleClass;
import cases.sample.Sample.SamplePair;
import typepacker.core.TypeInfomation;
import typepacker.core.TypePacker;

/**
 * ...
 * @author shohei909
 */
class TypePackerTestCase extends BaseTestCase
{
    public function new() { super(); }

    public function testBasic() {
        switch (TypePacker.toTypeInfomation("SamplePair")) {
            case TypeInfomation.CLASS("cases.sample.SampleStringValue", types):
                assertMapEquals(
                    [
                        "key" => "String",
                        "meta" => "cases.sample.SampleClass",
                        "value" => "cases.sample.SampleGenericAbstract<Int>",
                    ],
                    types
                );

                assertNotEquals(null, Type.resolveClass("cases.sample.SampleStringValue"));

            default:
                fail("must be CLASS");
        }

        switch (TypePacker.toTypeInfomation("SampleClass")) {
            case TypeInfomation.CLASS("cases.sample.SampleClass", types):
                assertMapEquals(
                    [
                        "c" => "cases.sample._Sample.SamplePrivateClass",
                        "e" => "cases.sample.SampleEnum",
                        "i" => "Int",
                        "str" => "String",
                        "intMap" => "Map<Int, List<Int>>",
                        "stringMap" => "Map<String, Int>",
                    ],
                    types
                );
            default:
                fail("must be CLASS");
        };

        switch (TypePacker.resolveType("cases.sample._Sample.SamplePrivateClass")) {
            case TypeInfomation.CLASS("cases.sample._Sample.SamplePrivateClass", types):
                assertMapEquals(
                    [
                        "c" => "cases.sample._Sample.SamplePrivateClass",
                        "e" => "cases.sample.SampleEnum",
                        "e2" => "cases.sample.SampleGenericEnum<Null<Int>>",
                        "i" => "Int",
                        "str" => "String",
                        "c2" => "cases.sample.SampleClass",
                        "abst" => "cases.sample.SampleAbstract",
                        "f" => "Float",
                        "arr" => "Array<Float>",
                        "intMap" => "Map<Int, List<Int>>",
                        "stringMap" => "Map<String, Int>",
                    ],
                    types
                );
            default:
                fail("must be CLASS");
        };

        switch (TypePacker.resolveType("cases.sample.SampleEnum")) {
            case TypeInfomation.ENUM("cases.sample.SampleEnum", constructors):
                assertArrayEquals(
                    constructors["LINK"],
                    [
                        "cases.sample.SampleEnum",
                        "cases.sample.SampleClass",
                    ]
                );
                assertArrayEquals(constructors["NONE"], []);
                assertFalse(constructors.exists("NON_pack"));
                assertFalse(constructors.exists("NON_pack_F"));

            default:
                fail("must be ENUM");
        };

        switch (TypePacker.resolveType("cases.sample.SampleGenericEnum<Null<Int>>")) {
            case TypeInfomation.ENUM("cases.sample.SampleGenericEnum", constructors):
                assertArrayEquals(
                    constructors["TEST"],
                    [
                        "Null<Int>",
                    ]
                );

            default:
                fail("must be ENUM");
        };

        switch (TypePacker.resolveType("cases.sample.SampleGenericAbstract<Int>")) {
            case TypeInfomation.ABSTRACT("Int"):
            default:
                fail("must be ABSTRACT(Int)");
        }

        switch (TypePacker.resolveType("Null<Int>")) {
            case TypeInfomation.PRIMITIVE(true, INT):
            default:
                fail("must be PRIMITIVE(true, INT)");
        };
    }
}

