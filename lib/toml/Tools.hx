package toml;

class Tools {
	public static function keys(data : Dynamic, ?parentKey : String = "") : Array<String> {

		if (Std.isOfType(data, haxe.ds.Result)) switch(cast(data, haxe.ds.Result<Dynamic, Dynamic>)) {
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
