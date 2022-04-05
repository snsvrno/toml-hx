package toml;

import result.Result;

/**
 * Pure haxe TOML spec compliant parser (with some bells and whistles).
 */
class Toml {

	/**
	 * a map of custom evaluators when evaluating string values from TOML.
	 *
	 * TODO: need to update this documentation with what a custom type looks like and what these parameters mean.
	 */
	static private var customEvals : Map<String, (text : String) -> Dynamic> = new Map();

	/**
	 * Parses a TOML string into a data structure.
	 *
	 * @param content the raw string toml
	 * @param source the name of the source (for error handling), typically this is a filename
	 * @return a `Result` of the datastructure, or an error string explaining what happened wrong.
	 */
	static public function parse(content : String, ?source : String) : Result<Dynamic, String> {
		var lexer = new toml.lexer.Lexer(content, source);
		lexer.run();

		var parser = lexer.toParser();
		return parser.run();
	}

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
	static public function load(... files : String) : Result<Dynamic, String> {
		for (f in files) {
			var content = sys.io.File.getContent(f);
			return parse(content, f);
		}

		return Ok({ });
	}

	/**
	 * Adds a custom parser callback function for evaluating custom data-types
	 *
	 * Normally the TOML parse can only evaluate core TOML types. A custom type can be
	 * used by registering an evaluator.
	 *
	 * TODO: fill in this documentation once I remind myself about this evaluator.
	 *
	 * @param name the name of the type, will be the same as appears in the TOML file.
	 * @param processer the function to be called to evaluate the string defining the type.
	 */
	static public function registerEval<T>(name : String, processer : (text : String) -> T) {
		customEvals.set(name, processer);
	}

	// TODO: should this thing be public?
	static public function getEval(name : String) : Null<(text : String) -> Dynamic> {
		return customEvals.get(name);
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
}
