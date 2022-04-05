package toml.parser;

import result.Result;
using toml.token.TokenTools;
using toml.token.TokenArrayTools;

class Parser {

	private var tokens : Array<toml.token.Metadata>;
	private var source : Null<String>;
	private var text : String;

	private var object : Context;
	private var metadata : Context;

	private function new() {
		object = new Context();
		metadata = new Context();
	}

	public static function fromTokens(tokens : Array<toml.token.Metadata>, text : String, ?source : String) : Parser {
		var parser = new Parser();
		parser.tokens = tokens;
		parser.text = text;
		parser.source = source;
		return parser;
	}

	public function run() : Result<Dynamic, String> {
		var token : Null<toml.token.Metadata>;

		while((token = nextToken()) != null) switch(token.token) {
			
			case Hash:
				// the comment tokens.
				var _ = tokensUntil(tokens, EOL);

			case LeftBracket:

				if (peakToken() == LeftBracket) {
					// array index setter.
					nextToken(); // remove the Left Bracket
					var contents = tokensUntil(tokens, RightBracket, LeftBracket);
					
					var firstbracket = nextToken();
					var nextbracket = nextToken();
					if (firstbracket.token != RightBracket) return Error(error(firstbracket, "expected ']'"));
					if (nextbracket.token != RightBracket) return Error(error(nextbracket, "expected ']'"));

					object.reset();
					switch(object.setArray(contents)) {
						case Error(msg): return Error(error(token, msg));
						case Ok(_):
					}


				} else {
					// scope change key.
					var contents = tokensUntil(tokens, RightBracket, LeftBracket);

					if (contents == null) return Error(error(token, "could not find closing bracket"));
					var bracket = nextToken();
					if (bracket.token != RightBracket) return Error(error(bracket, "expected ']'"));

					object.reset();
					switch(object.set(contents)) {
						case Error(msg): return Error(error(token, msg));
						case Ok(_):
					}

				}

			case Word(_):
				var left = {
					var ts = tokensUntil(tokens, Equals);
					ts.unshift(token);

					// removes the equals sign.
					var equals = nextToken();
					if (equals.token != Equals) return Error(error(equals, "expected EQUALS character"));
					
					ts;
				};

				var right = {
					var ts = tokensUntil(tokens, EOL);
					
					// removes the EOL
					var eol = nextToken();
					if (eol.token != EOL) return Error(error(eol, "expected EOL character"));

					ts;
				};

				switch(evaluate(... right)) {
					case Error(e): return Error(error(e.t, e.m));
					case Ok(value):
						var msg = object.setValue(left, value);
						if (msg != null) return Error(error(token, msg));
				}

			case EOL:

			default: return Error(error(token, "unimplemented"));

		}

		return Ok(object.object);
	}

	private function evaluate( ... tokens : toml.token.Metadata) : Result<Dynamic,{t:toml.token.Metadata, m:String}> {
		var tokens = tokens.toArray().trim();
		switch(tokens[0].token) {

			case LeftArrow:
				// is a custom thing
				var arrow = tokens.shift();
				var name = tokens.shift();
				var colon = tokens.shift();

				var properties = tokensUntil(tokens, RightArrow);
				var valuestring = properties.toString();

				var eval = toml.Toml.getEval(name.token.toString());
				if (eval == null) return Error({t:name, m:"no custom evaluate with this name found"});
				else return Ok(eval(valuestring));

			case Word(text):

				// checking for booleans
				if (text.toLowerCase() == "true") return Ok(true);
				else if (text.toLowerCase() == "false") return Ok(false);
				// checking for an int
				else if (Std.parseInt(text) != null) {

					// check if a float
					if (tokens[1] != null && tokens[1].token == Period) {
						var dec = if (tokens[2] != null) tokens[2].token.toString();
						else '';

						if(Std.parseInt(dec) == null) return Error({t:tokens[0],m:'cannot evaluate as a float'});

						var float = Std.parseFloat('$text.$dec');
						trace(float);
						if (!Math.isNaN(float)) return Ok(float);
						else return Error({t:tokens[0],m:'cannot evaluate as a float'});
					
					} else return Ok(Std.parseInt(text));
				}

				else return Error({t:tokens[0],m:'cannot evaluate to a value'});

			default: return Error({t:tokens[0],m:'cannot evaluate to a value'});

		}
	}

	//////////////////////////

	private function nextToken(?tokens : Array<toml.token.Metadata>) : Null<toml.token.Metadata> {
		if (tokens == null) return this.tokens.shift();
		else return tokens.shift();
	}

	private function peakToken(?tokens : Array<toml.token.Metadata>) : Null<toml.token.Token> {
		var t = if (tokens == null) this.tokens[0];
		else tokens[0];

		if (t == null) return null;
		else return t.token;
	}
	/**
	 * does not consume the token it is looking for.
	 */
	private function tokensUntil(tokens : Array<toml.token.Metadata>, target : toml.token.Token, ?starting : toml.token.Token) : Array<toml.token.Metadata> {
		var contents = [ ];

		// the supported nesting characters, so we return the right
		// scope / context.
		var nestingbrackets = 0;
		var nestingmoustaches = 0;

		// gets the first nest if we supply the starting character.
		switch (starting) {
			case LeftMoustache: nestingmoustaches = 1;
			case LeftBracket: nestingbrackets = 1;

			default:
		}

		while(tokens.length > 0) {

			// updates the nesting tracker.
			switch(peakToken(tokens)) {
				case LeftMoustache: nestingmoustaches += 1;
				case RightMoustache: nestingmoustaches -= 1;
				case LeftBracket: nestingbrackets += 1;
				case RightBracket: nestingbrackets -= 1;
				default:
			}

			if (peakToken(tokens).is(target) && nestingbrackets == 0 && nestingmoustaches == 0) return contents;
			else contents.push(nextToken(tokens));
		}

		return null;
	}
	//////////////////////////

	private function getText(line : Int) : String {
		var lines = text.split("\n");
		return lines[line-1];
	}

	private function error(token : toml.token.Metadata, msg : String) : String {
		var message : String = "ERROR: ";

		if (source != null) message += 'parsing $source';
		else message += 'parsing';

		message += '\n\n';

		// gets the line from the file.
		var line = getText(token.line);
		var formatedline = '${token.line}';
		while(formatedline.length < 4) formatedline = " " + formatedline;
		message += ' $formatedline | $line\n';

		// builds the arrowline
		var tstring = token.token.toString();
		var pos = line.indexOf(tstring, token.pos) + token.pos;
		var arrowline = "";
		for (_ in 0 ... pos) arrowline += " ";
		for (_ in 0 ... tstring.length) arrowline += "^";
		message += '        $arrowline';

		message += " " + msg;

		return message;
	}

	/*
		public function run() {
		var token : Null<toml.token.Token>;

		while((token = lexer.nextToken()) != null) switch(token) {

			case Word(_):
				
				var left = {
					var equals = lexer.indexOfToken(Equals);
					if (equals == -1) throw ('error');
					lexer.nextToken(); // the equals token.

					// adds the original token back into the list.
					var ts = lexer.drainTokens(equals);
					ts.unshift(token);
					ts;
				};


				var right = {
					var eol = lexer.indexOfToken(EOL);
					if (eol == -1) throw ('error');
					lexer.nextToken(); // the eol token
					lexer.drainTokens(eol);
				};

				set(left, right);

			case EOL:

			default:
				trace(token);
				throw 'unimplemented token => $token';
		}
	}

	private function set(left : Array<toml.token.Token>, right : Array<toml.token.Token>) {
		var trimmed = left.trim();
		var lastkey = trimmed.pop();
		setValue(lastkey, right);
	}

	private function setValue(left : toml.token.Token, right : Array<toml.token.Token>) {
		switch(left) {
			case Word(text):
				var existing = Reflect.getProperty(context, text);
				if (existing != null) throw('cannot set key $text multiple times');

				Reflect.setProperty(context, text, evaluate(... right));

			default:
				trace('unimplemented left value for set $left');
				throw('error');
		}
	}

	private function evaluate(... tokens : toml.token.Token) : Dynamic {
		return "empty";
	}
*/
}
