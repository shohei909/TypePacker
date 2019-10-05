package cases;
import nanotest.NanoTestCase;
import cases.sample.Sample.SampleClass;
import cases.sample.Sample.SamplePair;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;

/**
 * ...
 * @author shohei909
 */
class TypePackerTestCase extends BaseTestCase
{
    public function new() { super(); }

    public function testBasic() {
        switch (TypePacker.toTypeInformation("SamplePair")) {
            case TypeInformation.CLASS("cases.sample.SampleStringValue", _, types, names):
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

        switch (TypePacker.toTypeInformation("SampleClass")) {
            case TypeInformation.CLASS("cases.sample.SampleClass", _, types, names):
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
        switch (TypePacker.toTypeInformation("Class<SamplePair>")) {
            case TypeInformation.CLASS_TYPE:
				
			default:
                fail("must be CLASS TYPE");
		}
        switch (TypePacker.resolveType("cases.sample._Sample.SamplePrivateClass")) {
            case TypeInformation.CLASS("cases.sample._Sample.SamplePrivateClass", _, types, names):
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
            case TypeInformation.ENUM("cases.sample.SampleEnum", _, keys, constructors):
                assertArrayEquals(
                    constructors[keys["LINK"]],
                    [
                        "cases.sample.SampleEnum",
                        "cases.sample.SampleClass",
                    ]
                );
				assertEquals(0, keys["LINK"]);
				assertEquals(1, keys["NONE"]);
                assertArrayEquals(constructors[keys["NONE"]], []);
                assertFalse(keys.exists("NON_pack"));
                assertFalse(keys.exists("NON_pack_F"));

            default:
                fail("must be ENUM");
        };

        switch (TypePacker.resolveType("cases.sample.SampleGenericEnum<Null<Int>>")) {
            case TypeInformation.ENUM("cases.sample.SampleGenericEnum", _, keys, constructors):
                assertArrayEquals(
                    constructors[keys["TEST"]],
                    [
                        "Null<Int>",
                    ]
                );
				assertEquals(0, keys["TEST"]);

            default:
                fail("must be ENUM");
        };

        switch (TypePacker.resolveType("cases.sample.SampleGenericAbstract<Int>")) {
            case TypeInformation.ABSTRACT("Int"):
            default:
                fail("must be ABSTRACT(Int)");
        }

        switch (TypePacker.resolveType("Null<Int>")) {
            case TypeInformation.PRIMITIVE(true, INT):
            default:
                fail("must be PRIMITIVE(true, INT)");
        };
    }
}

