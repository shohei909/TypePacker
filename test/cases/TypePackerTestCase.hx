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
            case TypeInfomation.CLASS("cases.sample.SampleStringValue", types, names):
                assertMapEquals(
                    [
                        "key" => "String",
                        "meta" => "cases.sample.SampleClass",
                        "value" => "cases.sample.SampleGenericAbstract<Int>",
                    ],
                    types
                );
				assertArrayEquals(
					["key", "value", "meta"],
					names
				);
                assertNotEquals(null, Type.resolveClass("cases.sample.SampleStringValue"));

            default:
                fail("must be CLASS");
        }

        switch (TypePacker.toTypeInfomation("SampleClass")) {
            case TypeInfomation.CLASS("cases.sample.SampleClass", types, names):
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
				assertArrayEquals(["c","e","i","str","stringMap","intMap"], names);
            default:
                fail("must be CLASS");
        };

        switch (TypePacker.resolveType("cases.sample._Sample.SamplePrivateClass")) {
            case TypeInfomation.CLASS("cases.sample._Sample.SamplePrivateClass", types, names):
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
				assertArrayEquals(["c","e","i","str","stringMap","intMap","c2","abst","f","arr","e2"], names);
            default:
                fail("must be CLASS");
        };

        switch (TypePacker.resolveType("cases.sample.SampleEnum")) {
            case TypeInfomation.ENUM("cases.sample.SampleEnum", constructors, names):
                assertArrayEquals(
                    constructors["LINK"],
                    [
                        "cases.sample.SampleEnum",
                        "cases.sample.SampleClass",
                    ]
                );
				assertArrayEquals(["LINK", "NONE"], names);
                assertArrayEquals(constructors["NONE"], []);
                assertFalse(constructors.exists("NON_pack"));
                assertFalse(constructors.exists("NON_pack_F"));

            default:
                fail("must be ENUM");
        };

        switch (TypePacker.resolveType("cases.sample.SampleGenericEnum<Null<Int>>")) {
            case TypeInfomation.ENUM("cases.sample.SampleGenericEnum", constructors, names):
                assertArrayEquals(
                    constructors["TEST"],
                    [
                        "Null<Int>",
                    ]
                );
				assertArrayEquals(["TEST"], names);

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

