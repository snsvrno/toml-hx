package toml.parser;

import result.Result;
import toml.error.Error;

using result.ResultTools;
using toml.token.TokenTools;
using toml.token.TokenArrayTools;
using toml.token.MetadataTools;

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
				var comment = tokensUntil(tokens, [EOL]);
				var string = toml.token.TokenArrayTools.toString(comment);
				switch(processEscapeCharacters(string)) {
					case Error(err): return Error(error(comment[0].toError(err)));
					case Ok(_):
				}


			case LeftBracket:

				if (peakToken() == LeftBracket) {
					// array index setter.
					nextToken(); // remove the Left Bracket
					var contents = tokensUntil(tokens, [RightBracket], LeftBracket);
					
					var firstbracket = nextToken();
					var nextbracket = nextToken();
					if (firstbracket.token != RightBracket)
						return Error(error(firstbracket.toError("expected ']'")));
					if (nextbracket.token != RightBracket)
						return Error(error(nextbracket.toError("expected ']'")));

					object.reset();
					switch(object.setArray(contents)) {
						case Error(msg): return Error(error(token.toError(msg)));
						case Ok(_):
					}

				} else {
					// scope change key.
					var contents = tokensUntil(tokens, [RightBracket], LeftBracket);

					if (contents == null)
						return Error(error(token.toError("could not find closing bracket")));
					else if (contents.length == 0)
						return Error(error(token.toError("cannot have empty brackets")));

					var bracket = nextToken();

					if (bracket.token != RightBracket)
						return Error(error(bracket.toError("expected ']'")));

					object.reset();
					switch(object.set(contents)) {
						case Error(msg):
							return Error(error(token.toError(msg)));

						case Ok(_):
					}
				}

				// gets the rest of the stuff that might be on this line.
				var remainder = tokensUntil(tokens, [EOL]).trim();
					// the only thing allowed is a comment.
				if (remainder.length > 0 && remainder[0].token != Hash) {
					// TODO: make a way to capture the comment that might be here, so that we came maybe use it for something?
					return Error(error(remainder[0].toError("cannot have more than one statement on a line")));
				}

			case Word(_):
				var left = {
					var ts = tokensUntil(tokens, [Equals]);
					ts.unshift(token);

					// removes the equals sign.
					var equals = nextToken();
					if (equals.token != Equals)
						return Error(error(equals.toError("expected EQUALS character")));
					
					ts;
				};

				var right = {
					var ts = tokensUntil(tokens, [EOL]);
					
					// removes the EOL
					var eol = nextToken();
					if (eol.token != EOL)
						return Error(error(eol.toError("expected EOL character")));

					ts;
				};

				switch(evaluate(... right)) {
					case Error(e): return Error(error(e));
					case Ok(value):
						var msg = object.setValue(left, value);
						if (msg != null)
							return Error(error(token.toError(msg)));
				}

			case EOL:

			case Space(_) | Tab(_):
				// TODO: don't do anything, maybe we should fix this?

			default: 
				return Error(error(token.toError("unimplemented-default")));

		}

		// if there is nothing here, return an error saying its empty.
		if (Reflect.fields(object.object).length == 0) return Error("no object defined in TOML");
		else return Ok(object.object);
	}

	private function evaluate( ... tokens : toml.token.Metadata) : Result<Dynamic,Error> {
		var tokens = tokens.toArray().trim();
		switch(tokens[0].token) {

			case LeftArrow:
				// is a custom thing
				var arrow = tokens.shift();
				var name = tokens.shift();
				var colon = tokens.shift();

				var properties = tokensUntil(tokens, [RightArrow]);
				var valuestring = properties.toString();

				var eval = toml.Toml.getEval(name.token.toString());
				if (eval == null) return Error(name.toError("no custom evaluate with this name found"));
				else return Ok(eval(valuestring));

			case Word(text):
				// allowance for '.' because of floats.
				if (tokens.length != 1 && tokens[1].token != Period) 
					return Error(tokens[0].toError("more than one word on this line"));

				// checking for booleans
				if (text == "true") return Ok(true);
				else if (text.toLowerCase() == "true") return Error(tokens[0].toError("bool must be all lowercase"));
				else if (text == "false") return Ok(false);
				else if (text.toLowerCase() == "false") return Error(tokens[0].toError("bool must be all lowercase"));
				// checking for an int
				else if (Std.parseInt(text) != null) {

					// checks for correct placement of _ as separators if used.
					if (text.charAt(0) == "_" || text.charAt(text.length-1) == "_")
						return Error(tokens[0].toError("invalid placement of '_' separator; must have numbers on either side."));

					// check if a float
					if (tokens[1] != null && tokens[1].token == Period) {
						var dec = if (tokens[2] != null) tokens[2].token.toString();
						else '';

						if(Std.parseInt(dec) == null) return Error(tokens[0].toError('cannot evaluate as a float'));

						var float = Std.parseFloat('$text.$dec');
						if (!Math.isNaN(float)) return Ok(float);
						else return Error(tokens[0].toError('cannot evaluate as a float'));
					
					} else {
						var parsedint = Std.parseInt(text);
						return Ok(parsedint);
					}
				}

				else return Error(tokens[0].toError('cannot evaluate to a value'));

			case DoubleQuote:

				var string : String;
				var contents : Array<toml.token.Metadata>;
				if (peakToken(tokens) == DoubleQuote && peakToken(tokens,1) == DoubleQuote) {
					// we have a set of three quotes, meaning that we have a multiline string.

					// FIX: this is unimplemented because i don't have an easy way to get multiple lines
					// since the `run` function is doing line by line.
					return Error(tokens[0].toError('multi-line is unimplemented'));
/*
					// removes the quotes.
					tokens.shift();
					tokens.shift();
					tokens.shift();

					contents = tokensUntil(tokens, [DoubleQuote, DoubleQuote, DoubleQuote]);
					string = toml.token.TokenArrayTools.toString(contents);
					trace(string);

					tokens.shift();
					tokens.shift();
					tokens.shift();
*/
				} else {

					// removes the first quote.
					tokens.shift();
					contents = tokensUntil(tokens, [DoubleQuote]);
					string = toml.token.TokenArrayTools.toString(contents);
					tokens.shift(); // removes the last quote;

				}


				// HACK: checks for a comment.
				var trimmed = tokens.trim();
				if (trimmed.length > 0 && trimmed[0].token != Hash)
					return Error(tokens[0].toError('can only have one statement per line'));
				else {
					// and if its a comment we need to make sure it only has valid characters
					var hash = trimmed.shift(); // gets ride of the hash
					var string = toml.token.TokenArrayTools.toString(trimmed);
					var cleanedString = processEscapeCharacters(string);
					if (cleanedString.isError()) return Error(hash.toError(cleanedString.unwrapError()));
				}

				switch(processEscapeCharacters(string)) {
					case Error(msg): return Error(contents[0].toError(msg));
					case Ok(string): return Ok(string);
				}

			case LeftBracket:
				// is an array, so we need to build the parts of the array.
				var array : Array<Dynamic> = [];
			
				tokens.shift(); // removes the bracket.
				var contents = tokensUntil(tokens, [RightBracket], LeftBracket);
				var section = [];

				// added section.length so we can grab the last item if we don't
				// have a trailing comma.
				while(contents.length > 0 || section.length > 0) {
					var t = contents.shift();
					if (t == null || t.token == Comma) {
						section = section.trim();
						if (section.length > 0) switch(evaluate(...section)) {
							case Error(err): return Error(err);
							case Ok(d):
								array.push(d);
								while(section.length > 0) section.pop();
						}
					} else {
						section.push(t);
					}
				}

				return Ok(array);
				

			default: return Error(tokens[0].toError('cannot evaluate to a value'));

		}
	}

	//////////////////////////

	private function processEscapeCharacters(string : String) : Result<String, String> {
		var newString = "";
		var pos = -1;
		while((pos += 1) < string.length) {
			var char = string.charAt(pos);
			var code = string.charCodeAt(pos);
			if ((0 <= code && code <= 31) || code == 127) return Error('invalid character in string');

			if (char == "\\" && string.charAt(pos+1) == "u") {
				// unicode character, using the 4 digit notation

				if (string.length - pos - 1 < 4) return Error('invalid unicode escape');
				var hex = string.substr(pos+2,4);
				if (!toml.Unicode.isScalar(hex)) return Error('unicode must be a scalar value.');
				newString += toml.Unicode.fromHex(hex);
				pos += 5;

			} else if (char == "\\" && string.charAt(pos+1) == "U") {
				// unicode character using the 8 digit notation
				
				if (string.length - pos - 1 < 8) return Error('invalid unicode escape');
				var hex = string.substr(pos+2,8);
				if (!toml.Unicode.isScalar(hex)) return Error('unicode must be a scalar value.');
				newString += toml.Unicode.fromHex(hex);
				pos += 9;

			} else if (char == "\\") {
				switch(string.charAt(pos+1)) {
					case "b": newString += toml.Unicode.fromHex("0008");
					case "t": newString += toml.Unicode.fromHex("0009");
					case "n": newString += toml.Unicode.fromHex("000A");
					case "f": newString += toml.Unicode.fromHex("000C");
					case "r": newString += toml.Unicode.fromHex("000D");
					case "\"": newString += toml.Unicode.fromHex("0022");
					case "\\": newString += toml.Unicode.fromHex("005C");

					default: return Error('unknown escape character');
				}

				pos += 1;

			} else {
				// do nothing, just store the character

				newString += char;
			}
		}

		return Ok(newString);
	}

	private function nextToken(?tokens : Array<toml.token.Metadata>) : Null<toml.token.Metadata> {
		if (tokens == null) return this.tokens.shift();
		else return tokens.shift();
	}

	private function peakToken(?tokens : Array<toml.token.Metadata>, ?offset : Int = 0) : Null<toml.token.Token> {
		var tokens = if (tokens == null) this.tokens; else tokens;
		if (tokens.length <= offset) return null;
		return tokens[offset].token;
	}
	/**
	 * does not consume the token it is looking for.
	 */
	private function tokensUntil(tokens : Array<toml.token.Metadata>, target : Array<toml.token.Token>, ?starting : toml.token.Token) : Array<toml.token.Metadata> {
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

			var match = true;
			for (i in 0 ... target.length) if (peakToken(tokens, i).is(target[i]) == false) match = false;
			if (match && nestingbrackets == 0 && nestingmoustaches == 0) return contents;
			else contents.push(nextToken(tokens));
		}

		return null;
	}

	//////////////////////////////////////////////////////////////////////////////////////////

	inline private function getText(line : Int) : String {
		var lines = text.split("\n");
		return lines[line-1];
	}

	private function error(e : Error) : String {
		var message : String = "ERROR: ";

		if (source != null) message += 'parsing $source';
		else message += 'parsing';

		message += '\n\n';

		// gets the line from the file.
		var line = getText(e.token.line);
		var formatedline = '${e.token.line}';
		while(formatedline.length < 4) formatedline = " " + formatedline;
		message += ' $formatedline | $line\n';

		var tstring = e.token.token.toString();
		// HACK: not sure what is going on here or why i did this. fix it.
		//var pos = line.indexOf(tstring, token.pos) + token.pos;
		var pos = e.token.pos - 1;
		var arrowline = "";

		for (_ in 0 ... pos) arrowline += " ";
		for (_ in 0 ... tstring.length) arrowline += "^";
		message += '        $arrowline';

		message += " " + e.message;

		return message;
	}
}
