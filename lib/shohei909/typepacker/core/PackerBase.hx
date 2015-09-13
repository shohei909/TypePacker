package shohei909.typepacker.core;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * @author shohei909
 */
class PackerBase {
    public var baseParse(default, null):String->Dynamic;
    public var basePrint(default, null):Dynamic->String;

    public function new(basePrint:Dynamic->String, baseParse:String->Dynamic) {
        this.baseParse = baseParse;
        this.basePrint = basePrint;
    }

    macro public function print(self:ExprOf<PackerBase>, t:Expr, data:Expr):Expr
    {
        var portableType = PackerTools.toTypeInfomation(t);
        return macro $self.internalPrint($portableType, $data);
    }

    macro public function parse(self:ExprOf<PackerBase>, t:Expr, str:Expr):Expr
    {
        var portableType = PackerTools.toTypeInfomation(t);
        return macro $self.internalParse($portableType, $str);
    }

    public function internalPrint<T>(portableType:PortableTypeInfomation<T>, data:T):String {
        return this.basePrint(this.toPrintable(portableType, data));
    }

    public function internalParse<T>(portableType:PortableTypeInfomation<T>, str:String):T {
        return this.fromPrintable(portableType, this.baseParse(str));
    }

    public function fromPrintable<T>(typeInfo:PortableTypeInfomation<T>, data:Dynamic):T {
        return switch(typeInfo) {
            case PortableTypeInfomation.INT(nullable) :
                if (nullable && (data == null)) {
                    data;
                } else if (Std.is(data, Int)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Int");
				}
            case PortableTypeInfomation.STRING :
                if (data == null) {
                    data;
                } else if (Std.is(data, String)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String");
                }

            case PortableTypeInfomation.FLOAT(nullable) :
                if (nullable && (data == null)) {
                    data;
                } else if (Std.is(data, Float)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
                }
            case PortableTypeInfomation.BOOL(nullable) :
                if (nullable && (data == null)) {
                    data;
                } else if (Std.is(data, Bool)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
                }
            case PortableTypeInfomation.ENUM(name, constractors):
                (enumForParser(name, constractors, data) : Dynamic);
            case PortableTypeInfomation.CLASS(name, fields) :
                (classForParser(name, fields, data) : Dynamic);
            case ANONYMOUS(fields) :
                (objectForParser(fields, data) : Dynamic);
            case PortableTypeInfomation.STRING_MAP(value) :
                (mapForParser(value, data) : Dynamic);
            case PortableTypeInfomation.ARRAY(type) :
                (arrayForParser(type, data) : Dynamic);
            case PortableTypeInfomation.ABSTRACT(type) :
                (abstractForParser(type, data) : Dynamic);
        }
    }

    private function abstractForParser(typeString:String, data:Dynamic) {
        if (data == null) return null;
        var type = PackerTools.resolveType(typeString);
        return fromPrintable(type, data);
    }

    private function arrayForParser(typeString:String, data:Dynamic) {
        if (data == null) return null;
        if (!Std.is(data, Array)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
        }

        var result:Array<Dynamic> = [];
        var array:Array<Dynamic> = data;
        var type = PackerTools.resolveType(typeString);

        for (element in array) {
            result.push(fromPrintable(type, element));
        }

        return result;
    }

    private function enumForParser(enumName:String, constractors:Map<String,Array<String>>, data:Dynamic):EnumValue {
        if (data == null) return null;
        if (!Std.is(data, Array)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
        }

        var array:Array<Dynamic> = data;
        if (!Std.is(array[0], String)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be string");
        }

        var c:String = array[0];
        var paramTypes = constractors[c];
        var params = [];
        var e = Type.resolveEnum(enumName);

        for (i in 0...paramTypes.length) {
            var type = PackerTools.resolveType(paramTypes[i]);
            params.push(fromPrintable(type, array[i + 1]));
        }

        return Type.createEnum(e, c, params);
    }

    private function classForParser(className:String, fields:Map<String,String>, data:Dynamic):Dynamic {
        if (data == null) return null;
        var result = Type.createEmptyInstance(Type.resolveClass(className));
        for (key in fields.keys()) {
            var type = PackerTools.resolveType(fields[key]);
            var f = if (!Reflect.hasField(data, key)) {
                null;
            } else {
                Reflect.field(data, key);
            }

            var value = fromPrintable(type, f);
            Reflect.setField(result, key, value);
        }
        return result;
    }

    private function objectForParser(fields:Map<String,String>, data:Dynamic):Dynamic {
        if (data == null) return null;
        var result = {};
        for (key in fields.keys()) {
            var type = PackerTools.resolveType(fields[key]);
            var f = if (!Reflect.hasField(data, key)) {
                null;
            } else {
                Reflect.field(data, key);
            }

            var value = fromPrintable(type, f);
            Reflect.setField(result, key, value);
        }
        return result;
    }

    private function mapForParser(valueType:String, data:Dynamic):Map<String, Dynamic> {
        if (data == null) return null;
        var result = new Map<String, Dynamic>();
        var type = PackerTools.resolveType(valueType);

        for (key in Reflect.fields(data)) {
            result[key] = fromPrintable(type, Reflect.field(data, key));
        }

        return result;
    }

    public function toPrintable<T>(typeInfo:PortableTypeInfomation<T>, data:T) : Dynamic {
        return switch(typeInfo) {
            case PortableTypeInfomation.INT(nullable) :
                if (nullable && (data == null)) {
                    data;
                } else if (Std.is(data, Int)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Int");
                }
            case PortableTypeInfomation.STRING :
                if (data == null) {
                    data;
                } else if (Std.is(data, String)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be String");
                }
            case PortableTypeInfomation.FLOAT(nullable) :
                if (nullable && (data == null)) {
                    data;
                } else if (Std.is(data, Float)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
                }
            case PortableTypeInfomation.BOOL(nullable) :
                if (nullable && (data == null)) {
                    data;
                } else if (Std.is(data, Bool)) {
                    data;
                } else {
                    throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be Float");
                }
            case PortableTypeInfomation.ENUM(_, constractors):
                (enumForPrinter(constractors, data) : Dynamic);
            case PortableTypeInfomation.CLASS(_, fields) | ANONYMOUS(fields) :
                (objectForPrinter(fields, data) : Dynamic);
            case PortableTypeInfomation.STRING_MAP(value) :
                (mapForPrinter(value, (data : Dynamic)) : Dynamic);
            case PortableTypeInfomation.ARRAY(type) :
                (arrayForPrinter(type, data) : Dynamic);
            case PortableTypeInfomation.ABSTRACT(type) :
                (abstractForPrinter(type, data) : Dynamic);
        }
    }


    private function abstractForPrinter(typeString:String, data:Dynamic) {
        if (data == null) return null;
        var type = PackerTools.resolveType(typeString);
        return toPrintable(type, data);
    }

    private function arrayForPrinter(typeString:String, data:Dynamic) {
        if (data == null) return null;
        if (!Std.is(data, Array)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be array");
        }

        var result:Array<Dynamic> = [];
        var array:Array<Dynamic> = data;
        var type = PackerTools.resolveType(typeString);

        for (element in array) {
            result.push(toPrintable(type, element));
        }

        return result;
    }

    private function enumForPrinter(constractors:Map<String,Array<String>>, data:Dynamic) {
        if (data == null) return null;
        if (!Reflect.isEnumValue(data)) {
            throw new TypePackerError(TypePackerError.FAIL_TO_READ, "must be enum");
        }

        var result:Array<Dynamic> = [];

        var c = Type.enumConstructor(data);
        result.push(c);
        var paramTypes = constractors[c];
        var params = Type.enumParameters(data);

        for (i in 0...paramTypes.length) {
            var type = PackerTools.resolveType(paramTypes[i]);
            result.push(toPrintable(type, params[i]));
        }

        return result;
    }

    private function objectForPrinter(fields:Map<String,String>, data:Dynamic):Dynamic {
        if (data == null) return null;
        var result = {};
        for (key in fields.keys()) {
            var type = PackerTools.resolveType(fields[key]);
            var f = if (!Reflect.hasField(data, key)) {
                null;
            } else {
                Reflect.field(data, key);
            }

            var value = toPrintable(type, f);
            Reflect.setField(result, key, value);
        }
        return result;
    }

    private function mapForPrinter(valueType:String, data:Map<Dynamic, Dynamic>):Dynamic {
        if (data == null) return null;
        var result = { };
        var type = PackerTools.resolveType(valueType);

        for (key in data.keys()) {
            if (!Std.is(key, String)) {
                throw new TypePackerError(TypePackerError.FAIL_TO_READ, "key must be String");
            }
            var value = toPrintable(type, data.get(key));
            Reflect.setField(result, key, value);
        }
        return result;
    }
}
