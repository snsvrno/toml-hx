/**
 * Used for printing a section of code to the console, 
 * typically it will display some lines of code and then
 * visually show the error.
 */

package toml.printer;

#if termcolors
import termcolors.Termcolors.*;
#end

class Code {


	/*
	public static function old(outputType : String, message : String) {

		var lines = splitLines(this.text);
		var padding = '${lines.length}'.length;

		// the line before
		if (lineNumber != 1) {
			var number = '${lineNumber-1}';
			while(number.length < padding) number = " " + number;
			Sys.println('$number | ${lines[lineNumber-2]}');
		}

		// the line
		{
			var number = '${lineNumber}';
			while(number.length < padding) number = " " + number;
			#if termcolors
			// colors the character in question
			lines[lineNumber-1] = lines[lineNumber-1].substring(0, linePosition-1)
				+ red(lines[lineNumber-1].substring(linePosition-1,linePosition), [Background])
				+ lines[lineNumber-1].substring(linePosition);
			#end
			Sys.println('$number | ${lines[lineNumber-1]}');

		}

		// the error messages
		{ 
			var arrow ="";
			// offsets the arrow to start at column = 1
			for (_ in 0 ... (padding + 3)) arrow += " ";
			// moves the arrow until its at the start of the error
			for (_ in 0 ... linePosition - 1) arrow += " ";
			// extends the arrow so its the width of the entire error
			for (_ in 0 ... itemWidth) arrow += "^";
			
			#if termcolors
			arrow = yellow(arrow);
			outputType = switch(outputType.toLowerCase()) {
				case "error": red(outputType);
				case "warning": yellow(outputType);
				case _: blue(outputType);
			}
			#end
			Sys.println('$arrow $outputType: $message');
		}

		// the line after
		if (lineNumber != lines.length - 1) {
			var number = '${lineNumber+1}';
			while(number.length < padding) number = " " + number;
			Sys.println('$number | ${lines[lineNumber]}');
		}
	}
    */
}
