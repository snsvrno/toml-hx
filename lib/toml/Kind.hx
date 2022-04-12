package toml;

enum Kind {
	KString;
	KBool;
	KObject;
	KInt;
	KFloat;
	KArray;
}

function getKind(object : Dynamic) : Kind {
	if (Std.isOfType(object, Array)) return KArray;
	else if (Std.isOfType(object, String)) return KString;
	else switch(Type.typeof(object)) {
		case TObject: return KObject;
		case TInt: return KInt;
		case TBool: return KBool;
		case TFloat: return KFloat;
		default: throw('unknown type for $object');
	}
}
