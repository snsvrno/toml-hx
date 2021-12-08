package toml;

#if termcolors
import termcolors.Termcolors.*;
#end

class Log {
    public static function error(text : String) {
        Sys.println(text);
    }

    public static function warn() {

    }

    public static function parserError(msg : String, pos : toml.parser.Position, ?refPos : toml.parser.Position) {
        codeSection(msg, pos, refPos);
        throw '';
    }

    private static function codeSection(msg : String, pos : toml.parser.Position, ?refPos : toml.parser.Position) {
        printFileName(pos);
 
        if (pos.line != 1) printLine(pos.line-2, pos);
        printLine(pos.line - 1, pos, true);
        printMsgLine(msg, pos);
        if (refPos != null) {
            printLine(refPos.line - 1, refPos);
        }
        if (pos.line != pos.lines.length - 1) printLine(pos.line, pos);
    }

    /**
     * formatter to get the line number , will use colors if the library is available
     * @param number the current line number
     * @param padding the amount to pad the number.
     * @return String the formatted line number as a string
     */
    inline private static function lineNumber(number : Int, padding : Int) : String {
        var formatted = '${number}';
        while(formatted.length < padding) formatted = " " + formatted;
        return formatted;
    }

    inline private static function printFileName(pos : toml.parser.Position) {
        Sys.println(pos.file);
    }

    inline private static function printLine(line : Int, pos : toml.parser.Position, ?highlight : Bool = false, ?leadingPadding : Int = 0) {
        // how much space should we use when doing writing line numbers
        var padding = '${pos.lines.length}'.length;
        // the string used to separate the line number from the line content
        var lineSeparator = "  |  ";

        var leadPadding = "";
        if (leadingPadding != 0) {
            while(leadPadding.length < padding) leadPadding += " ";
            leadPadding += lineSeparator;
            for (_ in 0 ... leadingPadding) leadPadding += " ";
        } 

        var pretext = lineNumber(line, padding) + lineSeparator;
        var lineString = pos.lines[line];
        #if termcolors        
        if (highlight) { 
            lineString = white(lineString.substr(0, pos.column - 1))
                + red(lineString.substr(pos.column - 1, pos.errorLength))
                + white(lineString.substr(pos.column + pos.errorLength - 1));
            
        }
        #end
        
        Sys.println('$leadingPadding$pretext$lineString');
    }

    inline private static function printMsgLine(msg : String, pos : toml.parser.Position) {
        // how much space should we use when doing writing line numbers
        var padding = '${pos.lines.length}'.length;
        // the string used to separate the line number from the line content
        var lineSeparator = "  |  ";

        var pad = "";
        // moving the padding so we are at the start of the file text
        while(pad.length < padding) pad += " ";
        pad += lineSeparator;
        // moving the padding so that we are at the start of the error.
        for (_ in 1 ... pos.column) pad += " ";

        // the arrow that indicates what part of the text has the error.
        var arrow = "";
        while(arrow.length < pos.errorLength) arrow += "^";

        #if termcolors
        arrow = yellow(arrow, [Bold]);
        msg = white(msg);
        #end

        Sys.println('$pad$arrow $msg');
    }
}