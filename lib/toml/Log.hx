package toml;

#if termcolors
import termcolors.Termcolors.*;
#end

class Log {

    public static function parserError(msg : String, tokens : Array<toml.Token>) {
        trace(tokens);
    }

    /*
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
    */
}