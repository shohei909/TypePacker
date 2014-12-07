package shohei909.typepacker;
import haxe.PosInfos;
import nanotest.NanoTestCase;

/**
 * ...
 * @author shohei909
 */
class BaseTestCase extends NanoTestCase
{
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
	
	
	public function assertEnumEquals<T>(expected:EnumValue, actual:EnumValue, ?p:PosInfos)
	{
	}
}