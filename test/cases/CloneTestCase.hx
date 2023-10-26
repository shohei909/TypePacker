package cases;
import BaseTestCase;
import cases.sample.Sample.SampleClass;
import cases.sample.Sample.SampleEnum;
import typepacker.core.Clone;
import typepacker.core.TypeUtil;

/**
 * ...
 * @author shohei909
 */
class CloneTestCase extends BaseTestCase
{
    public function new() { super(); }

    public function testBasic():Void
	{
		var sa = new SampleClone(1, 2.0);
		var sb = sa.clone();
		
		assertEquals(1  , sb.a);
		assertEquals(2.0, sb.b);
		
		var s2a = new SampleClone2( -3, 1.1, sa);
		var s2b = s2a.clone();
		assertEquals(-3  , s2b.a  );
		assertEquals( 1.1, s2b.b  );
		assertEquals( 1  , s2b.x.a);
		assertEquals( 2.0, s2b.x.b);
		
		assertTrue (TypeUtil.isSame("Int", 1, 1));
		assertTrue (TypeUtil.isSame("SampleClone" , sa, sb));
		assertTrue (TypeUtil.isSame("SampleClone2", s2a, s2b));
		assertFalse(TypeUtil.isSame("SampleClone" , sa, s2a));
		
		sb.a = 5;
		assertFalse(TypeUtil.isSame("SampleClone", sa, sb));
		s2b.x.a = 6;
		assertTrue (TypeUtil.isSame("SampleClone" , s2a, s2b));
		assertFalse(TypeUtil.isSame("SampleClone2", s2a, s2b));
		
		var c = new SampleClass();
		var ea = SampleEnum.LINK(SampleEnum.NONE, c);
		var eb = TypeUtil.clone("cases.sample.SampleEnum", ea);
		assertTrue (TypeUtil.isSame("cases.sample.SampleEnum", ea, eb));
		
		c.intMap = null;
		assertFalse(TypeUtil.isSame("cases.sample.SampleEnum", ea, eb));
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
