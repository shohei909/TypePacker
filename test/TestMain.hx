package;
import cases.JsonPackerTestCase;
import cases.TypePackerTestCase;
import nanotest.NanoTestRunner;

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

#if (js || cpp || flash)
        //runner.add(new cases.YamlPackerTestCase());
#end

        runner.run();
    }
}
