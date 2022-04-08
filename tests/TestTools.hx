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

		switch(ttype) {
			case TObject: jsonTtype(value);

			case TInt: Reflect.setProperty(object, f, { type: "integer", value: '$value' });
			case TBool: Reflect.setProperty(object, f, { type: "bool", value: '$value' });
			case TFloat: Reflect.setProperty(object, f, { type: "float", value: '$value' });

			default:
		}
	}

}
