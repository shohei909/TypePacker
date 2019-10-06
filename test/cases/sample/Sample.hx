package cases.sample;
import haxe.ds.Vector;
import haxe.io.Bytes;

class SampleClass
{
    public var c:SamplePrivateClass;
    public var e:SampleEnum;
    public var i:Int;
    public var str:String;
    public var bytes:Bytes;
    public var stringMap:Map<String, Int>;
    public var intMap:Map<Int, List<Int>>;

    public function new() {
        i = 50;
        str = "hoge";

        var vec = Lambda.list([0, 5, 3]);
        intMap = [102 => vec];
        stringMap = [
            "test" => 100,
            "test2" => 101,
        ];
		bytes = Bytes.ofHex("0105");
    }
}

enum SampleEnum {
    LINK(e:SampleEnum, c:SampleClass);
    NONE;

    @:noPack NON_PACKED;
    @:noPack NON_PACKED_F(i:Int);
}

typedef SampleStruct = {
    @:noPack public var c : SamplePrivateClass;
    public var e : SampleEnum;
    public var i : SampleEnum;
}

abstract SampleAbstract(SampleEnum) {
    public function new(e) {
        this = e;
    }

    public function name() {
        return this.getName();
    }
}

private class SamplePrivateClass extends SampleClass
{
    public var c2:SampleClass;
    public var abst:SampleAbstract;
    public var f:Float;
    public var arr:Array<Float>;
    var e2:SampleGenericEnum<Null<Int>>;
    @:noPack public var i2:Int;
}

enum SampleGenericEnum<T> {
    TEST(t:T);
}

class SampleKeyValue<TKey, TValue> {
    public var key:TKey;
    public var value:TValue;
}

class SampleStringValue<T, TMeta> extends SampleKeyValue<String, T> {
    public var meta:TMeta;

    public function new () {
    }
}

abstract SampleGenericAbstract<T>(T) {
    public function new (value:T) {
        this = value;
    }
}

typedef SamplePair = SampleStringValue<SampleGenericAbstract<Int>, SampleClass>;
