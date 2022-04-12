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
	 * Converts a nexted object to a flat map
	 *
	 * In this context a flat map would be a single dimension key-value pair map. A data
	 * structure like this:
	 *
	 * ```haxe
	 * var data = {
	 * 	layer: {
	 * 		color: 0xFF0000,
	 * 		name: "string",
	 * 	}
	 * }
	 * ```
	 *
	 * would be converted into a structure like this:
	 *
	 * ```haxe
	 * var data = {
	 * 	"layer.color" => 0xFF0000,
	 * 	"layer.name" => "string",
	 * }
	 *
	 * ```
	 *
	 * @param object the data structure
	 * @parent the parent key; not used by end users. used in recussion
	 * return a map of key-value pairs
	 */
	static public function flatten(object : Dynamic, ?parent : String) : Map<String, Dynamic> {
		var flat : Map<String, Dynamic> = new Map();
		
		if (parent == null) parent = "";
	
		var fields = Reflect.fields(object);
		for (f in fields) {
			var value = Reflect.getProperty(object, f);
			if (Type.typeof(value) == TObject) {
				var sub = flatten(value, '$parent$f.');
				for (k => v in sub) flat.set(k,v);
			} else {
				flat.set('$parent$f', value);
			}
		}

		return flat;
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

	/**
	 * Merges data from `data2` into `data1` modifying it.
	 *
	 * Can pass `toml.Options` to modify behavior. See `toml.Options` to understand
	 * the default behavior.
	 *
	 * @param data1 the data structure that is the 'main' data, to be loaded into
	 * @param data2 the data structure that is the 'secondary' data, to be read and loaded from
	 *
	 * @return an error if one is encountered, returns `null` if success.
	 */
	public static function mergeInto(data1 : Dynamic, data2 : Dynamic, ?options : Array<toml.Options>) : Null<String> {
		if (options == null) options = toml.Toml.options;

		for (field in Reflect.fields(data2)) {
			var value = Reflect.getProperty(data2, field);

			if (!Reflect.hasField(data1, field)) {

				// if we don't have the field then it is easy, we can just set the value
				// as long as we don't have the switch set to prevent overwritting it.
				if (options.contains(PreventNewFields))
					return 'cannot merge because "$field" does not exist in the source: "PreventNewFields" is set';

				Reflect.setProperty(data1, field, value);

			} else {

				var oldValue = Reflect.getProperty(data1, field);
				var type1 = toml.Kind.getKind(oldValue);
				var type2 = toml.Kind.getKind(value);

				// checking if we care about keeping the same type, and if we do then ensuring that the two
				// types are identical.
				if (!options.contains(AllowDifferentTypes) && type1 != type2)
					return 'cannot merge because "$field" is of type "$type1" in the original object and "$type2" in the other';

				// checks if both objects are tables and then recursively merges into them.
				if (type1 == type2 && type1 == KObject) {
					var res = mergeInto(oldValue, value, options);
					if (res != null) return res;

				} else {
					// otherwise we just overwrite it.
					Reflect.setProperty(data1, field, value);
				}

			}
		}

		return null;
	}
}
