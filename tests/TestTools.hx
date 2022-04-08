/**
 * modifies the anonymous object in place and converts all final values
 * into [json encoding](https://github.com/BurntSushi/toml-test#json-encoding)
 * for toml-test
 */
function jsonTtype(object : Dynamic) {

	var fields = Reflect.fields(object);
	for (f in fields) {

		var value = Reflect.getProperty(object, f);
		var ttype = Type.typeof(value);

		if (Std.isOfType(value, Array)) {
			var array = cast(value, Array<Dynamic>);

			for (i in 0 ... array.length) {
				var v = { v: array[i] };
				jsonTtype(v);
				array[i] = v.v;
			}

			continue;
		}

		if (Std.isOfType(value, String)) {
			Reflect.setProperty(object, f, { type: "string", value: value });
			continue;
		}

		switch(ttype) {
			case TObject: jsonTtype(value);

			case TInt: Reflect.setProperty(object, f, { type: "integer", value: '$value' });
			case TBool: Reflect.setProperty(object, f, { type: "bool", value: '$value' });
			case TFloat: Reflect.setProperty(object, f, { type: "float", value: '$value' });

			default:
		}
	}
}
