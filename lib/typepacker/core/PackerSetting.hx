package typepacker.core;
import haxe.Constraints.Function;
import haxe.ds.Vector;

class PackerSetting {
	public var validates = true;
    public var forceNullable = false;
    public var useEnumIndex = false;
    public var bytesToBase64 = true;
    
    public function new () {}
}

