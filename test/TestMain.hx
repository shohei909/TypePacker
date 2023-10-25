package;
import cases.BytesPackerTestCase;
import cases.CloneTestCase;
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
        runner.add(new JsonPackerTestCase(true, true));
        runner.add(new JsonPackerTestCase(false, true));
        runner.add(new JsonPackerTestCase(false, false));
        runner.add(new BytesPackerTestCase(true));
        runner.add(new BytesPackerTestCase(false));
        runner.add(new CloneTestCase());

#if (js || cpp || flash)
        //runner.add(new cases.YamlPackerTestCase());
#end

        runner.run();
    }
}
