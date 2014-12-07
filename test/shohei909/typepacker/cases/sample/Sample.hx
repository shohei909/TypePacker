package shohei909.typepacker.cases.sample;


@:packable
class SampleClass
{
    @:packed public var c:SamplePrivateClass;
    @:packed public var e:SampleEnum;
    @:packed public var i:Int;
    @:packed public var str:String;
    
    public function new() {
        i = 50;
        str = "hoge";
    }
}

enum SampleEnum {
    LINK(e:SampleEnum, c:SampleClass);
    NONE;
    
    @:nonPacked NON_PACKED;
    @:nonPacked NON_PACKED_F(i:Int);
}

typedef SampleStruct = {
    @:nonPacked
    public var c : SamplePrivateClass;
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

@:packable
private class SamplePrivateClass extends SampleClass
{
    @:packed public var c2:SampleClass;
    @:packed public var abst:SampleAbstract;
    @:packed public var f:Float;
    @:packed public var arr:Array<Float>;
    public var i2:Int;
}
