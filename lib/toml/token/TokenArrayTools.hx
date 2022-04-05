package toml.token;

using toml.token.TokenTools;

/**
 * Helper tools for working with `Tokens`
 */
class TokenArrayTools {

	/**
	 * Trims "whitespace" tokens from the beginning and end of the array.
	 *
	 * "whitespace" is considered **Space**
	 */
	// TODO: add TAB to this also, and consider NL.
	inline public static function trim(keys : Array<toml.token.Metadata>) : Array<toml.token.Metadata> {
		var newArray = keys.copy();
		while(newArray.length > 0 && newArray[0].token.is(Space(0))) newArray.shift();
		while(newArray.length > 0 && newArray[newArray.length - 1].token.is(Space(0))) newArray.pop();
		return newArray;
	}

	inline public static function toString(tokens : Array<toml.token.Metadata>) : String {
		var string = "";
		for (t in tokens) string += t.token.toString();
		return string;
	}

}
