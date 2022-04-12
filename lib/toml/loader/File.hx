package toml.loader;

import result.Result;

class File {

	/**
	 * Loads one (or multiple) TOML files into a single data structure.
	 *
	 * The data structure is created sequentially, with the each subsequent file overwritting the
	 * data in the previous. Follows the following rules from TOML's spec:
	 *	1. key-values must be the same data type, cannot overwrite values of different types
	 *
	 * @param files a `Rest` of what files to load. can be zero to infinity
	 * @return a `Result` of the datastructure, or an error string explaining what happened wrong.
	 */
	public static function load(... files : String) : Result<Dynamic, String> {
		var data = { };

		for (f in files) {
			var content = sys.io.File.getContent(f);
			switch(toml.Toml.parse(content, f)) {
				case Error(error): return Error(error);
				case Ok(parsed):
					var err = toml.Tools.mergeInto(data, parsed);
					if (err != null) return Error(err);
			}
		}

		return Ok(data);
	}
}
