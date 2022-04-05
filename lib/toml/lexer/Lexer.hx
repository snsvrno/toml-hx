package toml.lexer;

using toml.token.TokenTools;

class Lexer {

	/*** an identifier for where the text came from, used for error handling */
	private var source : Null<String> = null;
	/*** the content that is parsed */
	private var text : String;

	/*** the parsing cursor, where in the text we currently are */
	private var cursor : Int = -1;
	/*** the lex'd tokens */
	private var tokens : Array<toml.token.Metadata> = [];

	/** the current line, used for error handling */
	private var line : Int = 1;
	/** the current position in that line, used for error handling */
	private var position : Int = 1;

	public function new(text : String, ?source : String) {
		this.text = text;
		this.source = source;
	}

	/**
	 * Runs the lexer and creates the `tokens`.
	 *
	 * Should only be called once, if called multiple times it should not do anything
	 * but that behavior is not guaranteed.
	 */
	public function run() {
		var char : Null<String>;

		while((char = nextChar()) != null) { 
			switch(char) {

				case "#": addToken(Hash);
				case "[": addToken(LeftBracket);
				case "]": addToken(RightBracket);
				case "{": addToken(LeftMoustache);
				case "}": addToken(RightMoustache);
				case "=": addToken(Equals);
				case ".": addToken(Period);
				case ",": addToken(Comma);
				case ";": addToken(SemiColon);
				case ":": addToken(Colon);
				case "\"": addToken(DoubleQuote);
				case "\'": addToken(SingleQuote);
				case "<": addToken(LeftArrow);
				case ">": addToken(RightArrow);
				case "\n" | "\r": 
					addToken(EOL);
					line += 1;
					position = 0;

				case " ":
					var length = countChar(" ");
					addToken(Space(length));
					position += length - 1;

				case "\t": 
					var length = countChar("\t");
					addToken(Tab(length));
					position += length - 1;

				default:
					if (peakLastToken() != null && peakLastToken().match(Word(_))) {
						var last = tokens.pop();
						addToken(last.token.addText(char), last.pos);
					} else
						addToken(Word(char));
			}

			position += 1;
		}
	}

	/**
	 * Converts the `Lexer` into a `Parser`.
	 */
	public function toParser() : toml.parser.Parser {
		// disconnects the tokens in the event that we try and do something
		// with this lexer afterwards, so that we don't some how get in the
		// way of the new parser that was just created.
		var ts = tokens;
		tokens = [ ];

		return toml.parser.Parser.fromTokens(ts, text, source);
	}

	////////////////////////////////////////////////////////////////////////////
	// PRIVATE INLINE HELPERS

	inline private function peakLastToken() : Null<toml.token.Token> {
		var t = tokens[tokens.length-1];
		if (t != null) return t.token;
		else return null;
	}

	inline private function countChar(char : String) : Int {
		var count = 1;
		while(peakChar() == char) {
			count += 1;
			nextChar();
		}
		return count;
	}

	inline private function addToken(token : toml.token.Token, ?pos : Int) {
		var position : Int = this.position;
		if (pos != null) position = pos;

		tokens.push({
			token: token,
			pos: position,
			line: line
		});
	}

	inline private function nextChar() : Null<String> {
		var char = peakChar();
		cursor += 1;
		return char;
	}

	inline private function peakChar(?size : Int = 1) : Null<String> {
		var peakCursor = cursor + 1;
		if (peakCursor >= text.length) return null;
		else return text.substr(peakCursor, size);
	}


}
