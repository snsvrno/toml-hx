package toml.token;

class TokenTools {

	/**
	 * adds a string to the end of a token that is a word.
	 * if the token is not a word then it will throw an error.
	 */
	public static function addText(token : Token, text : String) : Token {
		switch(token) {
			case Word(originalText):
				return Word(originalText + text);
			default:
				throw "token is $token not a word, cannot add text";
		}
	}

	/**
	 * checks if the supplied token is of the same type.
	 */
	public static function is(token : toml.token.Token, target : toml.token.Token) : Bool {
		if (token == target) return true;
		else switch ([token, target]) {

			case
				[Word(_), Word(_)] |
				[Space(_), Space(_)] |
				[Tab(_), Tab(_)]: return true;

			default:
				return false;
		}
	}

	public static function toString(token : toml.token.Token) : String {
		switch(token) {
			case Word(text): return text;
			case Hash: return "#";
			case LeftMoustache: return "[";
			case RightMoustache: return "]";
			case LeftBracket: return "{";
			case RightBracket: return "}";
			case SingleQuote: return "'";
			case DoubleQuote: return "\"";
			case Equals: return "=";
			case Period: return ".";
			case Comma: return ",";
			case Colon: return ":";
			case LeftArrow: return "<";
			case RightArrow: return ">";
			case SemiColon: return ";";
			case Space(length): return [ for (_ in 0 ... length) " " ].join("");
			case Tab(count): return [ for (_ in 0 ... count) "\t" ].join("");
			case EOL: return "\n";
		}
	}

}
