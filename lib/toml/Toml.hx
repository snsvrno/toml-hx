package toml;

class Toml {

	inline static public function parse(text : String, ?filename : String) : Dynamic {
		return toml.Parser.parse(text, filename);
	}

	inline static public function load(files : Array<String>) : Dynamic {
		var loaded : Null<Dynamic> = null;
		for (file in files) {

			if (!sys.FileSystem.exists(file)) error('cannot find file $file');
			var content = sys.io.File.getContent(file);
			var parsed = parse(content, file);

			if (loaded == null) loaded = parsed;
			else combine(loaded, parsed);
		}
		return loaded;
	}

	inline static public function tryLoad(files : Array<String>) : Dynamic {
		try { return load(files); }
		catch (e) { return { }; }
	}

	/**
	 * takes the contents of the second toml and adds it into the first,
	 * will overwrite all values and create new tables if needed.
	 * 
	 * will error if attempting to overwrite with different types.
	 * @param toml 
	 * @param second 
	 */
	private static function combine(toml : Dynamic, second : Dynamic, ?parent : Array<String>) {
		if (parent == null) parent = [];

		if (isObject(second)) for (k in Reflect.fields(second)) {
			parent.push(k);
			
			var value = Reflect.getProperty(second, k);
			
			if (isObject(value)) {
				// if the value is a table then we need to check if the toml object
				// also has a table. if its empty then we make a table, if its not
				// then we make sure its a table otherwise we error and quit.

				var tomlValue = Reflect.getProperty(toml, k);
				if (tomlValue == null) Reflect.setProperty(toml, k, { });
				else if (isObject(tomlValue)) combine(tomlValue, value, parent);
				else {
					error('key "${parent.join(".")}" is not the same type in the two objects: ${Type.typeof(value)} vs ${Type.typeof(tomlValue)}');
					throw "";
				}
			} else {

				// we are at the final value we need to check and set it.
				var tomlValue = Reflect.getProperty(toml, k);

				if (Type.typeof(value) != Type.typeof(tomlValue)) {
					error('key "${parent.join(".")}" is not the same type in the two objects: ${Type.typeof(value)} vs ${Type.typeof(tomlValue)}');
					throw "";
				} else {
					Reflect.setProperty(toml, k, value);
				}
				
			}

			parent.pop();
		}
	}

	inline private static function isObject(object : Dynamic) : Bool {
		return Type.getClass(object) == null 
			&& !Std.isOfType(object, Array)
			&& Reflect.isObject(object);
	}

}