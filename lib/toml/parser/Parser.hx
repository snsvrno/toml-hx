package toml.parser;

import result.Result;
import toml.error.Error;

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
				var _ = tokensUntil(tokens, EOL);

			case LeftBracket:

				if (peakToken() == LeftBracket) {
					// array index setter.
					nextToken(); // remove the Left Bracket
					var contents = tokensUntil(tokens, RightBracket, LeftBracket);
					
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
					var contents = tokensUntil(tokens, RightBracket, LeftBracket);

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

			case Word(_):
				var left = {
					var ts = tokensUntil(tokens, Equals);
					ts.unshift(token);

					// removes the equals sign.
					var equals = nextToken();
					if (equals.token != Equals)
						return Error(error(equals.toError("expected EQUALS character")));
					
					ts;
				};

				var right = {
					var ts = tokensUntil(tokens, EOL);
					
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

				var properties = tokensUntil(tokens, RightArrow);
				var valuestring = properties.toString();

				var eval = toml.Toml.getEval(name.token.toString());
				if (eval == null) return Error(name.toError("no custom evaluate with this name found"));
				else return Ok(eval(valuestring));

			case Word(text):
				if (tokens.length != 1) return Error(tokens[0].toError("more than one word on this line"));

				// checking for booleans
				if (text == "true") return Ok(true);
				else if (text.toLowerCase() == "true") return Error(tokens[0].toError("bool must be all lowercase"));
				else if (text == "false") return Ok(false);
				else if (text.toLowerCase() == "false") return Error(tokens[0].toError("bool must be all lowercase"));
				// checking for an int
				else if (Std.parseInt(text) != null) {

					// check if a float
					if (tokens[1] != null && tokens[1].token == Period) {
						var dec = if (tokens[2] != null) tokens[2].token.toString();
						else '';

						if(Std.parseInt(dec) == null) return Error(tokens[0].toError('cannot evaluate as a float'));

						var float = Std.parseFloat('$text.$dec');
						trace(float);
						if (!Math.isNaN(float)) return Ok(float);
						else return Error(tokens[0].toError('cannot evaluate as a float'));
					
					} else {
						var parsedint = Std.parseInt(text);
						if (text.length == '$parsedint'.length) return Ok(parsedint);
						else return Error(tokens[0].toError('cannot evaluate as an int'));
					}
				}

				else return Error(tokens[0].toError('cannot evaluate to a value'));

			default: return Error(tokens[0].toError('cannot evaluate to a value'));

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
