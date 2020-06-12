package;

import cases.sample.Sample.SampleAbstract;
import cases.sample.Sample.SampleClass;
import cases.sample.Sample.SampleEnum;
import haxe.DynamicAccess;
import haxe.ds.Vector;
import haxe.PosInfos;
import nanotest.NanoTestCase;
import typepacker.core.PackerBase;

/**
 * ...
 * @author shohei909
 */
class BaseTestCase extends NanoTestCase
{
    public function assertDynamicEquals<V>(expected:DynamicAccess<V>, actual:DynamicAccess<V>, ?p:PosInfos)
    {
        var ec = [for (i in expected) i].length;
        var ac = [for (i in actual) i].length;

        if (ec != ac) {
            fail('expected length ${ec} but was ${ac}', p );
        }

        for (i in expected.keys()) {
            if (expected[i] != actual[i]) {
                fail('expected [$i] ${expected[i]} but was ${actual[i]}', p );
            }
        }
    }
    public function assertMapEquals<K, V>(expected:Map<K, V>, actual:Map<K, V>, ?p:PosInfos)
    {
        var ec = [for (i in expected) i].length;
        var ac = [for (i in actual) i].length;

        if (ec != ac) {
            fail('expected length ${ec} but was ${ac}', p );
        }

        for (i in expected.keys()) {
            if (expected[i] != actual[i]) {
                fail('expected [$i] ${expected[i]} but was ${actual[i]}', p );
            }
        }
    }

    public function assertArrayEquals<T>(expected:Array<T>, actual:Array<T>, ?p:PosInfos)
    {
        var ec = expected.length;
        var ac = actual.length;

        if (ec != ac) {
            fail('expected length ${ec} but was ${ac}', p );
        }

        for (i in 0...expected.length) {
            if (expected[i] != actual[i]) {
                fail('expected [$i] ${expected[i]} but was ${actual[i]}', p );
            }
        }
    }

    public function assertListEquals<T>(expected:List<T>, actual:List<T>, ?p:PosInfos)
    {
        assertArrayEquals(Lambda.array(expected), Lambda.array(actual), p);
    }
    public function checkPacker(packer:PackerBase) {
        assertNotEquals(null, packer.parse("Map<Int, List<String>>", packer.print("Map<Int, List<String>>", [1 => Lambda.list(["1"])])));
        assertNotEquals(null, packer.parse("Map<String, Int>", packer.print("Map<String, Int>", ["1" => 1])));

        assertEquals(1, packer.parse("Int", packer.print("Int", 1)));
        assertEquals(1.1, packer.parse("Float", packer.print("Float", 1.1)));
        assertEquals(1.0, packer.parse("Float", packer.print("Float", 1)));
        assertEquals("サンプル入力", packer.parse("String", packer.print("String", "サンプル入力")));
        assertEquals(null, packer.parse("Empty", packer.print("Empty", null)));

        assertNotEquals(null, packer.parse("Empty", packer.print("Empty", {})));
        {
            var data = packer.parse("ArrayEmpty", packer.print("ArrayEmpty", [null, {}]));
            assertEquals(2, data.length);
            assertEquals(null, data[0]);
            assertNotEquals(null, data[1]);
        }

        assertNotEquals(null, packer.parse("SampleClass", packer.print("SampleClass", new SampleClass())));
        assertNotEquals(null, packer.parse("IntData", packer.print("IntData", { i : -12 })));
        assertNotEquals(null, packer.parse("IntData", packer.print("IntData", new SampleClass())));
        assertEquals(SampleEnum.NONE, packer.parse("SampleEnum", packer.print("SampleAbstract", new SampleAbstract(SampleEnum.NONE))));
    }
}

typedef Empty = {};
typedef ArrayEmpty = Array<Empty>;
typedef IntData = {i : Int};
typedef StringVector = Vector<String>;
