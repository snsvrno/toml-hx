package toml;

#if termcolors
import termcolors.Termcolors.*;
#end

class Parser {

	//////////////////////////////////////////////////////

	inline static public function parse(string : String, ?filename : String) : Dynamic {
		return new Parser(string, filename).doParse();
	}

	private var text : String;
	private var cursor : Int = -1;

	//////////////////////////////////////////////////////
	// some more information for debugging.
	private var position : toml.parser.Position;
	private var positions : Map<String, toml.parser.Position> = new Map();
	// the current line number.
	// how big is the item of interest / that caused an issue.
	private var itemWidth : Int = 1;
	// where we requested something, so for example
	// if we are looking for a closing character, this is
	// where that starting character should be.
	private var startingRequestCursor : Int = 0;
	private var startingRequestLineNumber : Int = 1;

	function new(string : String, ?filename : String) {
		this.text = string + "\r";
		
		position = {
			lines : splitLines(string),
			file: filename,
			line: 1,
			column: 1,
			errorLength: 1,
		};
	}

	//////////////////////////////////////////

	/**
	 * parse the text. will continue until EOF
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

					// checks that we don't have anything else on this line
					var remaining = charsUntil("\n", "\r");
					if (remaining != null) { 
						remaining = trim(remaining, " ","\t");
						if (remaining.length > 0) {
							// adjust the position to be at the start of the dangling text.
							position.column -= remaining.length;
							position.errorLength = remaining.length;
							toml.Log.parserError('can\'t have anything after a table declaration', position);
					
						}
					}

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
					var key = trim(left, " ", "\r", "\n").split(".");

					{
						var length = 0;
						for (k in key) length += k.length;
						validateKey(key, left.length - length);
					}

					nextChar(); // removes the "=" character.
					var right = charsUntil("\n", "\r");

					if (right == null) { 
						error("can't find left side of assignment");
						return object;
					}

					var rightParsed = parseText(right);
					if (!set(context, key, rightParsed)) return object;
			}
		}

		return object;
	}

	/**
	 * parse the give `text` and returns an object.
	 * @param text
	 */
	private function parseText(text : String) : Null<Dynamic> {
		text = trim(text, " ", "\r", "\n");
		var char = text.charCodeAt(0);

		////////////////////////////////////////////////////////
		// TYPE PARSING

		// boolean checking
		if (text.toLowerCase() == "true") return true;
		else if (text.toLowerCase() == "false") return false;

		// array checking
		else if (char == 91) { // "["
			// gets the inside section of the array.
			var sections = respectfulSplit(text, ",", true);
			var array : Array<Dynamic> = [ ];
			for (section in sections) {
				array.push(parseText(section));
			}
			return array;
		}

		// inline table checking
		// "{"
		else if (char == 123) {
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

		// number checking
		// 0 <= char <= 0
		else if (48 <= char && char <= 57) {
			var int = Std.parseInt(text);
			var float = Std.parseFloat(text);
			if (int == float) return int;
			else return float;
		}

		// string checking
		// " or '
		else if (char == 34 || char == 39) {
			var closingPosition = text.indexOf(String.fromCharCode(char), 1);
			if (closingPosition <= 0) {
				error("unterminated string");
				return null;
			}

			var string = text.substr(1, closingPosition - 1);
			var remaining = trim(text.substr(closingPosition + 1), " ", "\r", "\n");

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
			if (section != null && !Std.isOfType(section, Array) && Type.typeof(section) != TObject) {			
				for (kp in keys) {
					if (kp == k) break;
					else position.column -= kp.length;
				}
				position.column += 1;
				position.errorLength = k.length;

				var msg = '"$fullkey" is already defined as "$section", cannot define as a table';
				var olderPos = positions.get(fullkey);
				toml.Log.parserError(msg, position, olderPos);
			} else if (section != null) {
				object = section;
			} else {
				var part = { };
				Reflect.setProperty(object, k, part);
				object = part;
			}
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
				position.line += 1;
				position.column = 0;
			}

			// increments the position.
			position.column += 1;
			cursor += 1;

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
// startingRequestCursor = linePosition;
// startingRequestLineNumber = lineNumber;

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
		//error('could not find character(s) "$st"', ', started looking at Line $startingRequestLineNumber, Column $startingRequestCursor');
		error('unknown');
		return null;
	}

	/**
	 * Splits the text by lines, looking for `\n` and `\r` characters. Does not
	 * remove duplicates, i.e. could possibly have empty strings in the array if
	 * there are multiple new lines together.
	 * @param text to split 
	 */
	inline private function splitLines(text : String) : Array<String> {
		var lines = [];
		var wline = "";

		for (i in 0 ... text.length) {
			if (text.charAt(i) == "\n" || text.charAt(i) == "\r") {
				lines.push(wline);
				wline = "";
			} else wline += text.charAt(i);
		}
		return lines;
	}

	/**
	 * trimps the beginning and end of the string, removing the `parts`
	 * @param text the string to trim
	 * @param characters to look for when performing the trim
	 */
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

	inline static public function trimArray(array : Array<String>, ... parts : String) {
		for (i in 0 ... array.length) {
			array[i] = trim(array[i], ...parts);
		}
	}

	/**
	 * splits the string while respecting "[ ]" and "{ }" nesting.
	 * @param string `String` the string to split
	 * @param splitter `char` a string of what to split, expects a char: string of length 1
	 * @param useStartingChar `bool` if enabled, takes the first character as the start of a grouping
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

	/**
	 * checks if the characters used inside a key are valid TOML characters
	 * @param keyparts the split `(by '.')` key
	 * @param errorReportingOffset an offset backwards when reporting errors, used because the array might have trimmed whitespace.
	 */
	private function validateKey(keyparts : Array<String>, ?errorReportingOffset : Int = 0) {

		for (k in keyparts) {

			// checks if this is a blank string, can't have empty sections
			if (k.length == 0) {

				// adjusting the position so we are at the point where we have an
				// error.
				for (kp in keyparts) {
					if (kp == k) break;
					else position.column -= kp.length;
				}

				position.column -= errorReportingOffset;
				
				// calls the fault.
				toml.Log.parserError('cannot have a table name with an empty section', position);
			}

			// checks if there are any invalid characters inside the key string.
			for (i in 0 ... k.length) {
				var char = k.charCodeAt(i);
				if ((48 <= char && char <= 57)
				|| (97 <= char && char <= 122)
				|| (65 <= char && char <= 90)
				|| (45 == char)
				|| (95 == char)
					) continue;

				else {
					// the following is all just so we get a nice pretty
					// error message.
					//
					// now we need to backtrack to where we started
					for (j in 0 ... keyparts.length) { 
						position.column -= keyparts[j].length;
						if (0 < keyparts.length-1) position.column -= 1;
					}
					// and now step through until we find the keypart in question
					for (j in 0 ... keyparts.length) {
						if (keyparts[j] == k) { 
							itemWidth = 1;
							position.column += i;
							break;
						} else {
							position.column += keyparts[j].length;
							if (0 < keyparts.length-1) position.column += 1;
						}
					}

					position.column -= errorReportingOffset;

					toml.Log.parserError('invalid character in table key', position);
				}
			}
		}
	}
}