package toml.loader;

import result.Result;

/**
 * Loads a group of files into an array
 */
class Collection {

	/**
	 * Loads all toml files in the directory into an array object
	 *
	 * @param path the folder path
	 * @param extension the extension of the file, defaults to "toml"
	 *
	 * return a result of the array object on sucess or a string of the error on error
	 */
	public static function fromFolder(path: String, ?extension : String = "toml") : Result<Array<Dynamic>, String> {
		var array = [];

		for (file in sys.FileSystem.readDirectory(path)) {
			var fullPath = haxe.io.Path.join([path, file]);

			if (sys.FileSystem.isDirectory(fullPath)) {
				// if we have a folder then we must check if we want to recursively collect
				// the files.
				if (toml.Toml.options.contains(Recursive)) {
					switch(fromFolder(fullPath, extension)) {
						case Error(error): return Error(error);
						case Ok(subitems):
							for (si in subitems) array.push(si);
					}
				}
			} else {
				if (haxe.io.Path.extension(file) == extension) {
					var err = loadInto(array, fullPath);
					if (err != null) return Error(err);
				}
			}
		}

		return Ok(array);
	}

	/**
	 * Loads the TOML files into an array
	 *
	 * @param files string path to the files to load
	 *
	 * @return an array of the resulting data on success and a error string on error
	 */
	public static function fromFiles(...files : String) : Result<Array<Dynamic>, String> {
		var array = [];

		for (f in files) {
			var err = loadInto(array, f);
			if (err != null) return Error(err);
		}

		return Ok(array);
	}

	/**
	 * Adds resulting parsed object to the collection
	 *
	 * @param collection an existing array of items to add into
	 * @param contents the string of the raw toml contents
	 * @param source the source of the string for rich error messages
	 *
	 * @return returns nothing on a success and an error string on error
	 */
	public static function add(collection : Array<Dynamic>, contents : String, ?source : String) : Null<String> {

		switch(toml.Toml.parse(contents, source)) {
			case Error(err): return err;
			case Ok(content): collection.push(content);
		}

		return null;
	}

	/**
	 * Inline helper function that loads the file into the collection
	 */
	inline private static function loadInto(collection : Array<Dynamic>, file : String) : Null<String> {
		if (!sys.FileSystem.exists(file)) return 'cannot access file "$file", does not exist?';
		var contents = sys.io.File.getContent(file);
		return add(collection, contents, file);
	}

}
