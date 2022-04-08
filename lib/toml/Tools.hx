package toml;

import result.Result;

class Tools {
	/**
	 * returns a flattend list of all keys (in dot notation)
	 */
	public static function keys(data : Dynamic, ?parentKey : String = "") : Array<String> {

		if (Std.isOfType(data, Result)) switch(cast(data, Result<Dynamic, Dynamic>)) {
			case Ok(insideData): data = insideData;
			case Error(_): return [ ];
		}

		var foundkeys : Array<String> = [ ];

		for (k in Reflect.fields(data)) {
			var value = Reflect.getProperty(data, k);

			var fullkey = parentKey + k;

			if (Type.typeof(value) == TObject) {
				// we check if its empty, because we could add a property
				// without any values if we just want the default values.
				if (Reflect.fields(value).length == 0) foundkeys.push(fullkey);
				else for (subk in keys(value, fullkey + ".")) foundkeys.push(subk);
			} else
				foundkeys.push(fullkey);
		}

		return foundkeys;
	}

	/**
	 * gets the value of the provided key
	 *
	 * the key can should be provided in dot notation `a.b.c` and array
	 * access should be indexed if looking for a specific item in an
	 * array `a.b[2].c`
	 *
	 * @param data the loaded toml data
	 * @param key the key in dot notation
	 *
	 * @return the value, or null if it doesn't exist.
	 */
	public static function get(data : Dynamic, key : String) : Null<Dynamic> {
		var parts = key.split(".");
		var thiskey = parts.shift();

		var data = Reflect.getProperty(data, thiskey);
		
		if (parts.length > 0) {
			if (data == null) return data;
			else return get(data, parts.join("."));
		} else return data;
	}
}
