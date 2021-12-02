package haxe.format;

class TomlParser {
	inline static public function parse(string : String) : Dynamic {
		return new TomlParser(string).doParse();
	}

	private var text : String;
	private var cursor : Int = -1;

	//////////////////////////////////////////////////////
	// some more information for debugging.

	// the current line number.
	private var lineNumber : Int = 1;
	private var linePosition : Int = 1;
	// where we requested something, so for example
	// if we are looking for a closing character, this is
	// where that starting character should be.
	private var startingRequestCursor : Int = 0;
	private var startingRequestLineNumber : Int = 1;

	function new(string : String) {
		this.text = string + "\r";
	}

	//////////////////////////////////////////

	/**
	 * parse the text. will continue until EOF unless
	 * another character is provided.
	 */
	private function doParse() : Dynamic {
		var object = { };
		var context = object;

		var char;

		while((char = nextChar()) != null) {
			switch(char) {

				case c if (c == String.fromCharCode(10)): // a new line (LF)
				case c if (c == String.fromCharCode(13)): // a new line (CR)

				// a comment, will just throw that away.
				case "#":
					var comment = charsUntil("\n", "\r");

				// a table definition
				case "[":
					var key = charsUntil("]");
					nextChar(); // consumes the "]"
					if (key == null || key.length == 0) error("empty table definition");
					var sections = key.split(".");

					// sets the context so that we can start setting
					// into this new table.
					context = setContext(sections, object);
					if (context == null) return object;

				// an assignment
				case _:
					var left = char += charsUntil("=");
					if (left == null) { 
						error("can't find right side of assignment");
						return object;
					}

					nextChar(); // removes the "=" character.
					var right = charsUntil("\n", "\r");

					if (right == null) { 
						error("can't find left side of assignment");
						return object;
					}

					var key = trim(left, " ", "\r", "\n").split(".");
					var rightParsed = parseText(right);
					if (!set(context, key, rightParsed)) return object;
			}
		}

		return object;
	}

	private function parseText(text : String) : Null<Dynamic> {
		text = trim(text, " ", "\r", "\n");
		var char = text.charCodeAt(0);

		// checking if we have a boolean
		if (text.toLowerCase() == "true") return true;
		else if (text.toLowerCase() == "false") return false;

		// we have an array, so lets try and separate it smartly.
		else if (char == 91) { // "["
			// gets the inside section of the array.
			var sections = respectfulSplit(text, ",", true);
			var array : Array<Dynamic> = [ ];
			for (section in sections) {
				array.push(parseText(section));
			}
			return array;
		}

		// we have an inline table, so lets try and separate it smartly.
		else if (char == 123) { // "{"
			// gets the inside section of the array.
			var sections = respectfulSplit(text, ",", true);
			var object = { };
			for (section in sections) {

				if (section.length == 0) continue;

				var parts = respectfulSplit(section, "=");

				if (parts.length != 2) { 
					error("invalid assignment section");
					return null;
				}

				var key = parts[0].split(".");
				var value = parseText(parts[1]);

				if (!set(object, key, value)) return object;
			}

			return object;
		}

		// the code is between 0 and 9, so this is a number
		else if (48 <= char && char <= 57) {
			var int = Std.parseInt(text);
			var float = Std.parseFloat(text);
			if (int == float) return int;
			else return float;
		}

		// checking if we have a string.
		else if (char == 34) { // "
			var closing = text.indexOf("\"", 1);
			if (closing <= 0) {
				error("unterminated string");
				return null;
			}
			var string = text.substr(1, closing-1);
			var remaining = trim(text.substr(closing+1), " ", "\r", "\n");

			// catching something else after a string, this is not valid.
			if (remaining.length > 0 && remaining.substr(0,1) != "#") {
				error("cannot have multiple statements on a line");
				return null;
			}

			return string;
		}

		else if (char == 39) { // '
			var closing = text.indexOf("\'", 1);
			if (closing <= 0) {
				error("unterminated string");
				return null;
			}
			var string = text.substr(1, closing-1);
			var remaining = trim(text.substr(closing+1), " ", "\r", "\n");

			// catching something else after a string, this is not valid.
			if (remaining.length > 0 && remaining.substr(0,1) != "#") {
				error("cannot have multiple statements on a line");
				return null;
			}

			return string;
		}

		else {
			error('unknown object "$text", don\'t know what it is.');
		}

		return text;

	}

	//////////////////////////////////////////

	private function set(context : Dynamic, keys : Array<String>, value : Dynamic) : Bool {
		var fullkey = keys.join(".");
		var finalKey = keys.pop();
		var workingContext = setContext(keys, context);

		var oldValue = Reflect.getProperty(workingContext, finalKey);
		if (oldValue != null) {
			error('property $fullkey is already set, cannot set again');
			return false;
		}

		Reflect.setProperty(workingContext, finalKey, value);
		return true;
	}

	private function setContext(keys : Array<String>, object : Dynamic) : Null<Dynamic> {
		validateKey(keys);

		var fullkey = keys.join(".");
		for (k in keys) {

			var section = Reflect.getProperty(object, k);
			
			// checking if the key was already set, because if it is
			// we need to make sure we are not redefining it with something
			// else, i.e. it was a bool but now its a table ???
			if (section != null && Std.isOfType(section, Dynamic)) {
				error('property $k of $fullkey is already defined, can\'t define it again');
				return null;
			}

			var part = { };
			Reflect.setProperty(object, k, part);
			object = part;
		}
		return object;
	}

	inline private function nextChar() : Null<String> {
		var char = peakChar();
		if (char == null) return null;
		else {

			// increments the extra debug info, though this is kind of wrong ...
			// because this will mark the new-line character as on the wrong spot, but
			// that should be ok because we shouldn't really error on a new-line ...
			if (char == "\r" || char == "\n") {
				linePosition = 0;
				lineNumber += 1;
			}

			// increments the position.
			cursor += 1;
			linePosition += 1;

			return char;
		}
	}

	inline private function peakChar(?size : Int = 1) : Null<String> {
		var peakCursor = cursor + 1;
		if (peakCursor >= text.length) return null
		else return text.substr(peakCursor, size);
	}

	private function charsUntil(...endingChar : String) : Null<String> {

		// marking where we started, so we have some more information for
		// the trace.
		startingRequestCursor = linePosition;
		startingRequestLineNumber = lineNumber;

		var content = "";
		var char;

		while ((char = peakChar()) != null) {
			for (ec in endingChar) if (char == ec) return content;
			content += nextChar();
		}


		var st = "";
		for (ec in endingChar) {
			st + ec + ", ";
		}
		error('could not find character(s) "$st"', ', started looking at Line $startingRequestLineNumber, Column $startingRequestCursor');
		return null;
	}

	inline private function error(text : String, ?positionInfo : String) {
		if (positionInfo == null) positionInfo = ', Line $lineNumber, Column $linePosition';
		Sys.println("TomlParser: " + text + positionInfo);
		throw "errr" ;
	}


	inline static public function trim(text : String, ... parts:String) : String {
		// checking the left side.
		while(text.length > 0) {
			var found = false;
			for (p in parts) if (text.substr(0,1) == p) found = true;

			if (found) text = text.substr(1);
			else break;
		}

		// checking the right side.
		while(text.length > 0) {
			var found = false;
			for (p in parts) if (text.substr(text.length-1,1) == p) found = true;

			if (found) text = text.substr(0,text.length-1);
			else break;
		}

		return text;
	}

	/**
	 * splits the string while respecting "[ ]" and "{ }" nesting.
	 */
	public function respectfulSplit(string : String, splitter : String, ?useStartingChar : Bool = false) : Array<String> {
		var sections = [ ];
		var startingChar : Null<String> = if (useStartingChar) string.substr(0, 1) else null;
		var bracketDepth = 0;
		var curlyDepth = 0;
		var insideSingleQuote = false;
		var insideDoubleQuote = false;

		var closer : Null<String> = null;
		var cursor = 0;
		var workingString = "";

		if (startingChar != null) {
			if (startingChar == "[") { 
				closer = "]";
				bracketDepth = 1;
			} else if (startingChar == "{") { 
				closer = "}";
				curlyDepth = 1;
			} else {
				error('expected ');
			}

			cursor = 1;
		}

		while(cursor < string.length) {
			var char = string.substr(cursor, 1);
			if (char == splitter
			&& (
				// checking if we are inside where we should be, so we don't
				// go splitting things from nested items.
				startingChar == "[" && curlyDepth == 0 && bracketDepth == 1
				|| startingChar == "{" && curlyDepth == 1 && bracketDepth == 0
				|| startingChar == null && curlyDepth == 0 && bracketDepth == 0
			)
			&& !insideDoubleQuote && !insideSingleQuote 
			&& workingString.length > 0) {
				sections.push(trim(workingString, " ", "\r", "\n"));
				workingString = "";
				
			} else { 
				switch(char) {
					case "[": bracketDepth += 1;
					case "]": 
						bracketDepth -= 1;
						if (startingChar == "[" && bracketDepth == 0 && curlyDepth == 0) break;
				
					case "{": curlyDepth += 1;
					case "}": 
						curlyDepth -= 1;
						if (startingChar == "{" && bracketDepth == 0 && curlyDepth == 0) break;

					case "\"" :
						if (insideDoubleQuote) insideDoubleQuote = false;
						else if (!insideSingleQuote) insideDoubleQuote = true;

					case "\'" :
						if (insideSingleQuote) insideSingleQuote = false;
						else if (!insideDoubleQuote) insideSingleQuote = true;

					case _:
				}

				workingString += char;
			}
			cursor += 1;
		}

		if (workingString.length > 0) {
			sections.push(trim(workingString, " ", "\r", "\n"));
			workingString = "";
		}

		if (bracketDepth == 0 && curlyDepth == 0 && !insideDoubleQuote && !insideSingleQuote) {
			if (cursor >= string.length - 1) return sections;
			else error("found closing item, but there is more after ... ");
		} else  error("cannot find closer");

		return [];
	}

	private function validateKey(keyparts : Array<String>) {
		for (k in keyparts) {
			for (i in 0 ... k.length) {
				var char = k.charCodeAt(i);

				if ((48 <= char && char <= 57)
				&& (97 <= char && char <= 122)
				&& (65 <= char && char <= 90)
				&& (45 == char)
				&& (95 == char)
					) continue;

				else error('invalid character" ${k.substr(i,1)}" in key');
			}
		}
	}
}