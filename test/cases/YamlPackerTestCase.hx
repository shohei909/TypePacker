package cases;
import BaseTestCase;
import cases.YamlPackerTestCase.YamlPacker;
import typepacker.core.PackerBase;
import typepacker.core.PackerSetting;
import yaml.Parser.ParserOptions;
import yaml.Yaml;


/**
 * @author shohei909
 */

class YamlPackerTestCase extends BaseTestCase {
    public function test() {
        checkPacker(new YamlPacker());
    }
}

class YamlPacker extends PackerBase {
    public function new () {
        var setting = new PackerSetting();
        super(Yaml.render.bind(_), Yaml.parse.bind(_, new ParserOptions().useObjects()), setting);
    }
}
