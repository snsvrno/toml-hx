package toml.lexer;

using haxe.EnumTools;

enum Token {
    Hash;
    LeftMoustache; RightMoustache;
    LeftBracket; RightBracket;
    SingleQuote; DoubleQuote;
    Equals;
    Period;
    Comma; Colon; SemiColon;

    Space(length : Int);
    Tab(count : Int);
    Word(text : String);
    EOL;
}

class TokenTools {
    static public function asWordAddText(token : Token, text : String) : Token {
        switch(token) {
            case Word(content): return Word(content + text);
            default: throw "can only use with a Word";
        }
    }

    static public function is(t : Token, otherToken : Token) : Bool return t == otherToken;

    static public function isRightBracket(t : Token) : Bool return t.match(RightBracket);
    static public function isWord(t : Token) : Bool return t.match(Word(_));
    static public function isEol(t : Token) : Bool return t.match(EOL);
    static public function isEquals(t : Token) : Bool return t.match(Equals);
    static public function isSpace(t : Token) : Bool return t.match(Space(_));
    static public function isTab(t : Token) : Bool return t.match(Tab(_));
    static public function isPeriod(t : Token) : Bool return t.match(Period);

    static public function getWord(t : Token) : String {
        switch(t) {
            case Word(text): return text;
            default: throw 'cannot get a word if the token is a "$t"';
        }
    }

    static public function toString(t : Token) : String {
        switch(t) {
            case Space(length): 
                var text = "";
                while(text.length < length) text += " ";
                return text;

            case Tab(length): 
                var text = "";
                while(text.length < length) text += "\t";
                return text;

            case Word(text): return text;

            case Hash: return "#";
            case LeftMoustache: return "{";
            case RightMoustache: return "}";
            case LeftBracket: return "[";
            case RightBracket: return "]";
            case SingleQuote: return "\'";
            case DoubleQuote: return "\"";
            case Equals: return "=";
            case Period: return ".";
            case Comma: return ",";
            case Colon: return ":";
            case SemiColon: return ";" ;
            case EOL: return "\n";
        }
    }
}