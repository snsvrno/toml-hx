package toml.lexer;

import toml.lexer.Token.TokenTools;

class Lexer {
    private var source : Null<String> = null;
    private var text : String;
    private var cursor : Int = -1;

    public var tokens : Array<toml.Token> = [ ];

    #if codesense
    private var currentLine : Int = 1;
    private var linePosition : Int = 0;
    #end

    public function new(text : String, ?source : String) {
        this.text = text;
        this.source = source;
    }

    public function toParser() : toml.parser.Parser {
        return new toml.parser.Parser(tokens, source);
    }

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
                case "\n" | "\r": addToken(EOL);
                
                case " ":
                    var count = 1;
                    while (peakChar() == " ") {
                        count += 1; 
                        nextChar();
                    }
                    addToken(Space(count));
                
                case "\t":
                    var count = 1;
                    while (peakChar() == "\t") {
                        count += 1; 
                        nextChar();
                    }
                    addToken(Tab(count));

                default: 
                    if (peakLastToken() != null && TokenTools.isWord(peakLastToken())) {
                        addToken(TokenTools.asWordAddText(lastToken(), char));
                    } else {
                        addToken(Word(char));
                    }
            }
        }

    }

    private function addToken(token : toml.lexer.Token) {
        #if codesense
        var length = switch(token) {
            case Word(text): text.length;
            case Space(length): length;
            case Tab(length): length;
            default: 1;
        }
        tokens.push(new codesense.CodeSense(token, linePosition - length + 1, linePosition + 1, currentLine));
        #else
        tokens.push(token);
        #end
    }

    private function charsUntil(...endingChar : String) : Null<String> {

		// marking where we started, so we have some more information for
		// the trace.

		var content = "";
		var char;

		while ((char = peakChar()) != null) {
			for (ec in endingChar) if (char == ec) return content;
			content += nextChar();
		}

		return null;
	}

    inline private function lastToken() : Null<toml.Token> {
        return tokens.pop();
    }

    inline private function peakLastToken() : Null<toml.Token> {
        return tokens[tokens.length-1];
    }

	inline private function nextChar() : Null<String> {
		var char = peakChar();

        cursor += 1;
        #if codesense
        if (char == "\n" || char == "\r") {
            linePosition = 0;
            currentLine += 1;
        } else linePosition += 1;
        #end

		if (char == null) return null;
		else return char;
	}

	inline private function peakChar(?size : Int = 1) : Null<String> {
		var peakCursor = cursor + 1;
		if (peakCursor >= text.length) return null
		else return text.substr(peakCursor, size);
	}
}