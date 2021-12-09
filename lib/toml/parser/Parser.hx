package toml.parser;

import toml.lexer.Token.TokenTools;

class Parser {
    
    private var source : Null<String> = null;

    private var tokens : Array<toml.Token>;
    public var object : Dynamic = { };

    // map of dynamic path to file for tracing back the value
    private var contextMap : Map<String, String> = new Map();

    public function new(tokens : Array<toml.Token>, ?source : String) {
        this.tokens = tokens;
        this.source = source;
    }

    public function parse(text : String, ?source : String) {
        var lexer = new toml.lexer.Lexer(text, source);
        this.source = source;
        lexer.run();
        tokens = lexer.tokens;
        run();
    }

    public function run() {

        var context : Dynamic = object;
        var contextPath : Array<String> = [];

        var token : Null<toml.Token>;

        while((token = nextToken()) != null) {
            #if codesense
            switch(token.toOriginalType()) {
            #else
            switch(token) {
            #end
                case EOL: // blank line.

                case Hash:
                    var commentTokens = [ ];
                    while(peakToken() != null && !TokenTools.isEol(peakToken())) commentTokens.push(nextToken());

                case LeftBracket:

                    // getting the table name / key. 
                    var key : Array<toml.Token> = [ ];
                    while(peakToken() != null && !TokenTools.isRightBracket(peakToken())) key.push(nextToken());
                    if (peakToken() == null) throw "unimplemented error: bracket peak token null";
                    
                    // removing the ']'
                    nextToken();
                    // checking that there isn't anything else on this line.
                    while(peakToken() != null && !TokenTools.isEol(peakToken())) {
                        if (!TokenTools.isSpace(peakToken()) && !TokenTools.isTab(peakToken())) throw "unimplemented error: statement on same line as table declaration";
                        else nextToken();
                    }

                    // removes the eol
                    if (!TokenTools.isEol(nextToken())) throw "unimplemented error: expected end of line - left bracket";

                    // cleaning the path because we start from the root when we 
                    // have these table declarations
                    while(contextPath.length > 0) contextPath.pop();
                    // sets the current setting context to the the table key.
                    context = setContext(object, contextPath, key);

                default:

                    // catch all for an assignment
                    var leftside : Array<toml.Token> = [ token ];
                    while(peakToken() != null && !TokenTools.isEquals(peakToken())) leftside.push(nextToken());
                    if (peakToken() == null) throw "unimplemented error: line is not an assignment??";
                    if (leftside.length == 0) throw "unimplemented error: no left side to assignment";

                    // remove the equals sign
                    nextToken();

                    var rightside : Array<toml.Token> = [];
                    while(peakToken() != null && !TokenTools.isEol(peakToken())) rightside.push(nextToken());

                    // removes the eol
                    if (peakToken() != null && !TokenTools.isEol(nextToken())) throw "unimplemented error: expected end of line - default";
                    if (rightside.length == 0) throw "unimplemented error: no right side to assignment";

                    var localPath : Array<String> = [ for (cp in contextPath) cp ];
                    set(context, localPath, leftside, rightside);
            }
        }

        return object;
    }

    private function parseExpression(exp : Array<toml.Token>) : Dynamic {
        trim(exp);

        if (exp.length == 0) throw "unimplemented error: attempting to parse empty expression";
        
        var parsed : Array<Dynamic> = [];

        var token : toml.Token;
        while(exp.length > 0) {
            #if codesense
            switch((token = exp.shift()).toOriginalType()) {
            #else
            switch(token = exp.shift()) {
            #end
                case LeftBracket: 

                    var array : Array<Dynamic> = [];
                    var contents = tokensUntil(exp, RightBracket, token);
                    if (contents == null) throw "unimplemented error: array is not closed (1)";

                    for (item in splitByToken(contents, Comma)) {
                        array.push(parseExpression(item));
                    }

                    // checks we actually have the closing bracket.
                    if (exp[0] != null && !TokenTools.is(exp[0], RightBracket)) throw "unimplemented error: array is not closed (2)";
                    else exp.shift();

                    parsed.push(array);

                case LeftMoustache:
                    var table = { };
                    var contents = tokensUntil(exp, RightMoustache, token);
                    if (contents == null) throw "unimplemented error: table is not closed (1)";

                    for (items in splitByToken(contents, Comma)) {

                        // catch all for an assignment
                        var leftside : Array<toml.Token> = [ ];
                        while(items[0] != null && !TokenTools.isEquals(items[0])) leftside.push(items.shift());
                        if (items[0]  == null) throw "unimplemented error: line is not an assignment?? (2)";
                        if (leftside.length == 0) throw "unimplemented error: no left side to assignment (2)";
    
                        // remove the equals sign
                        items.shift();
    
                        var rightside : Array<toml.Token> = [];
                        while(items[0] != null && !TokenTools.isEol(items[0])) rightside.push(items.shift());
    
                        if (rightside.length == 0) throw "unimplemented error: no right side to assignment (2)";
    
                        set(table, [], leftside, rightside);
                        
                    }

                    // checks we actually have the closing bracket.
                    if (exp[0] != null && !TokenTools.is(exp[0], RightMoustache)) throw "unimplemented error: table is not closed (2)";
                    else exp.shift();

                    parsed.push(table);

                case DoubleQuote | SingleQuote :
                    var string = [ ];
                    while(exp[0] != null && !TokenTools.is(exp[0], token)) {
                        string.push(exp.shift());
                    }
                    // removes the last token (or a null);
                    exp.shift();
                    // makes the string
                    parsed.push([for (s in string) TokenTools.toString(s)].join(""));

                case Space(_) | Tab(_) : // just ignore these.
                case Hash: break; // an end of line comment, stop looking at things.

                case Word(text):

                    // checking for booleans
                    if (text.toLowerCase() == "true") parsed.push(true);
                    else if (text.toLowerCase() == "false") parsed.push(false);

                    // checking for a float.
                    else if (exp[0] != null && TokenTools.isPeriod(exp[0])) {
                        // attempt to parse it as a float
                        exp.shift(); // gets the period.
                        // checks if there is another word after the period.
                        if (exp[0] != null && TokenTools.isWord(exp[0])) {
                            text += "." + TokenTools.getWord(exp.shift());
                        }
                        var float = Std.parseFloat(text);
                        if (!Math.isNaN(float)) parsed.push(float);
                    }

                    // checking for an int
                    else if (Std.parseInt(text) != null) parsed.push(Std.parseInt(text));

                default:
                    throw 'unimplemented error: unknown expression => ${token}';

            }
        }

        if (parsed.length == 1) return parsed[0];
        else throw 'unimplemented error: parsed multiple expressions => ${parsed}';
    }

    private function setContext(context : Dynamic, contextPath: Array<String>, keys : Array<toml.Token>) : Dynamic {

        // trims the tokens, removing ones that don't do anyhting
        trim(keys);

        for (k in keys) {
            if (!TokenTools.isWord(k)) continue;
            var keyString = TokenTools.getWord(k);

            var section = Reflect.getProperty(context, keyString);

			if (section != null && !Std.isOfType(section, Array) && Type.typeof(section) != TObject) {
                toml.Log.parserError('cannot write over existing table value', [ k ]);
				//var msg = '"$fullkey" is already defined as "$section", cannot define as a table';
			} else if (section != null) {
				context = section;
			} else {
				var part = { };
				Reflect.setProperty(context, keyString, part);
				context = part;
			}

            contextPath.push(keyString);
        }

        return context;
    }

    private function set(context : Dynamic, contextPath : Array<String>, keys : Array<toml.Token>, value : Array<toml.Token>) {

        // trims the tokens, removing ones that don't do anyhting
        trim(keys);

        if (keys.length == 0) throw "unimplemented error: cannot set a value with no value";

        var flatKey : String = {
            var array : Array<String> = [];
            for (cp in contextPath) array.push(cp);
            for (k in keys) if (TokenTools.isWord(k)) array.push(TokenTools.getWord(k));
            array.join(".");
        }

        var finalKey = TokenTools.getWord(keys.pop());
        var currentValue =  Reflect.getProperty(context, finalKey);
        var newValue = parseExpression(value);


        // need to check if we are trying to overwrite the value from the same source file, we can't
        // declare the same key multiple times from the same file.
        if (currentValue != null) {
            var originalSource = contextMap.get(flatKey);
            if (originalSource == source) throw 'unimplemented error: cannot assign a value to the same key in a single file';
        }

        // part of the "cascading" functionality, well allow overwriting if the types are the same
        if (currentValue != null && Type.typeof(currentValue) != Type.typeof(newValue)) 
            throw 'unimplemented error: cannot overwrite a value with a value of a different type';


        context = setContext(context, contextPath, keys);
        Reflect.setProperty(context, finalKey, newValue);
        // save the path so we know what file this value was originally assigned in.
        contextMap.set(flatKey, source);
    }

    /**
     * remove leading and lagging spaces from the list of tokens.
     * @param keys 
     */
    inline private function trim(keys : Array<toml.Token>) {
        while(keys.length > 0 && TokenTools.isSpace(keys[0])) keys.shift();
        while(keys.length > 0 && TokenTools.isSpace(keys[keys.length - 1])) keys.pop();
    }

    inline private function nextToken() : Null<toml.Token> {
        return tokens.shift();
    }

    inline private function peakToken() : Null<toml.Token> {
        if (tokens.length == 0) return null;
        else return tokens[0];
    }

    /**
     * returns null if it doesn't find the requested token
     * @param tokens 
     * @param t 
     * @param startingToken for nesting
     * @return Array<toml.Token>
     */
    inline private function tokensUntil(tokens : Array<toml.Token>, t : toml.lexer.Token, ?startingToken : toml.Token) : Null<Array<toml.Token>> {
        var brackets = 0;
        var moustaches = 0;

        if (startingToken != null) {
            if (TokenTools.is(startingToken, LeftMoustache)) moustaches += 1;
            else if (TokenTools.is(startingToken, LeftBracket)) brackets += 1;
        }
        
        var insides = [];
        
        while(tokens.length > 0) {
            var shifted = tokens.shift();

            if (TokenTools.is(shifted, LeftMoustache)) moustaches += 1;
            else if (TokenTools.is(shifted, RightMoustache)) moustaches -= 1;
            else if (TokenTools.is(shifted, LeftBracket)) brackets += 1;
            else if (TokenTools.is(shifted, RightBracket)) brackets -= 1;

            if (moustaches == 0 && brackets == 0 && TokenTools.is(shifted, t)) {
                tokens.unshift(shifted);
                break;
            } else {
                insides.push(shifted);
            }
        }

        if (tokens[0] == null) return null
        else return insides;
    }

    inline private function splitByToken(tokens : Array<toml.Token>, t : toml.lexer.Token) : Array<Array<toml.Token>> {
        var brackets = 0;
        var moustaches = 0;
        
        var splits = [ ];

        var currentSet = [ ];
        while(tokens.length > 0) {
            var shifted = tokens.shift();
            if (TokenTools.is(shifted, LeftMoustache)) moustaches += 1;
            else if (TokenTools.is(shifted, RightMoustache)) moustaches -= 1;
            else if (TokenTools.is(shifted, LeftBracket)) brackets += 1;
            else if (TokenTools.is(shifted, RightBracket)) brackets -= 1;

            if (moustaches < 0 || brackets < 0) throw "unimplemented error: unmatching brackets";

            if (TokenTools.is(shifted, t) && brackets == 0 && moustaches == 0) {
                splits.push(currentSet);
                currentSet = [];
            } else currentSet.push(shifted);
        }

        splits.push(currentSet);

        return splits;
    }
}