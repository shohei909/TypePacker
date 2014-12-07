package shohei909.typepacker;

/**
 * ...
 * @author shohei909
 */

class TypePackerError
{
	static public inline var FAIL_TO_READ:String = "failToRead";
	public var type:String;
	public var message:String;
	
	public function new (type:String, message:String) {
		this.type = type;
		this.message = message;
	}
	
	public function toString () {
		return "TypePackerError#" + type + " : " + message;
	}
}
