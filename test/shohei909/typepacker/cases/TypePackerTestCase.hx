package shohei909.typepacker.cases;
import nanotest.NanoTestCase;
import shohei909.typepacker.cases.sample.Sample.SampleClass;
import shohei909.typepacker.PortableTypeInfomation;

/**
 * ...
 * @author shohei909
 */
class TypePackerTestCase extends BaseTestCase
{
    public function new() { super(); }
    public function testBasic() {
        switch (TypePacker.toTypeInfomation(SampleClass)) {
            case PortableTypeInfomation.CLASS("shohei909.typepacker.cases.sample.SampleClass", types):
                assertMapEquals(
                    [
                        "c" => "shohei909.typepacker.cases.sample._Sample.SamplePrivateClass",
                        "e" => "shohei909.typepacker.cases.sample.SampleEnum",
                        "i" => "Int",
                        "str" => "String",
                    ],
                    types
                );
            default:
                fail("must be CLASS");
        };
        
        switch (TypePacker.resolveType("shohei909.typepacker.cases.sample._Sample.SamplePrivateClass")) {
            case PortableTypeInfomation.CLASS("shohei909.typepacker.cases.sample._Sample.SamplePrivateClass", types):
                assertMapEquals(
                    [
                        "c" => "shohei909.typepacker.cases.sample._Sample.SamplePrivateClass",
                        "e" => "shohei909.typepacker.cases.sample.SampleEnum",
                        "i" => "Int",
                        "str" => "String",
                        "c2" => "shohei909.typepacker.cases.sample.SampleClass",
                        "abst" => "shohei909.typepacker.cases.sample.SampleAbstract",
                        "f" => "Float",
                        "arr" => "Array<Float>",
                    ],
                    types
                );
            default:
                fail("must be CLASS");
        };
        
        switch (TypePacker.resolveType("shohei909.typepacker.cases.sample.SampleEnum")) {
            case PortableTypeInfomation.ENUM("shohei909.typepacker.cases.sample.SampleEnum", constructors):
                assertArrayEquals(
                    constructors["LINK"], 
                    [
                        "shohei909.typepacker.cases.sample.SampleEnum",
                        "shohei909.typepacker.cases.sample.SampleClass",
                    ]
                );
                assertArrayEquals(constructors["NONE"], []);
                assertFalse(constructors.exists("NON_PACKED"));
                assertFalse(constructors.exists("NON_PACKED_F"));
                
            default:
                fail("must be ENUM");
        };
    }
}