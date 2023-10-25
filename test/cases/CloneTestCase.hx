package cases;
import nanotest.NanoTestCase;
import cases.sample.Sample.SampleClass;
import cases.sample.Sample.SamplePair;
import cases.sample.Sample.SampleEnum;
import typepacker.core.Clone;
import typepacker.core.TypeInformation;
import typepacker.core.TypePacker;
import BaseTestCase;

/**
 * ...
 * @author shohei909
 */
class CloneTestCase extends BaseTestCase
{
    public function new() { super(); }

    public function testBasic():Void
	{
		var sampleClone = new SampleClone(1, 2.0).clone();
		
		assertEquals(1  , sampleClone.a);
		assertEquals(2.0, sampleClone.b);
		
		var sampleClone2 = new SampleClone2( -3, 1.1, sampleClone).clone();
		assertEquals(-3  , sampleClone2.a  );
		assertEquals( 1.1, sampleClone2.b  );
		assertEquals( 1  , sampleClone2.x.a);
		assertEquals( 2.0, sampleClone2.x.b);
	}
}


class SampleClone implements Clone
{
	public var a:Int;
	public var b:Float;
	
	public function new(a:Int, b:Float)
	{
		this.a = a;
		this.b = b;
	}
}

class SampleClone2 extends SampleClone
{
	public var x:SampleClone;
	public function new(a:Int, b:Float, x:SampleClone)
	{
		super(a, b);
		this.x = x;
	}
}
