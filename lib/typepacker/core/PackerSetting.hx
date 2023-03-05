package typepacker.core;
import haxe.Constraints.Function;
import haxe.ds.Vector;

class PackerSetting {
	public var validates = true;
    public var forceNullable = false;
	public var intAsFloat = false;
    public var useEnumIndex = false;
    public var bytesToBase64 = true;
    public var initializesWithEmptyArray         = false;
    public var initializesWithEmptyMap           = false;
    public var initializesWithEmptyList          = false;
    public var initializesWithEmptyVector        = false;
    public var initializesWithEmptyDynamicAccess = false;
    public var initializesWithEmptyAnonymous     = false;
    public var initializesWithFalse              = false;
    public var initializesWithZero               = false;
	
    public function new () {}
}
