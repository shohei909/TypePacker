package shohei909.typepacker;
import haxe.Serializer;
import haxe.Unserializer;
import nanotest.NanoTestRunner;
import shohei909.typepacker.cases.JsonPackerTestCase;
import shohei909.typepacker.cases.sample.Sample.SampleEnum;
import shohei909.typepacker.cases.TypePackerTestCase;

/**
 * ...
 * @author shohei909
 */
class TestMain
{
	static function main() 
	{
		var runner = new NanoTestRunner();
		runner.add(new TypePackerTestCase());
		runner.add(new JsonPackerTestCase());
		runner.run();
	}
}
