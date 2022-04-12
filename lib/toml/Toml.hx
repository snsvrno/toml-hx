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
	 * Global options when performing operations
	 *
	 * Anything added here will always be executed when running operations at runtime.
	 * Macro's behavior is not guaranteed.
	 *
	 * These are not additive, setting options on a per-function basic will cause `toml`
	 * to completely ignore this.
	 */
	static public var options : Array<toml.Options> = [];

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
}
