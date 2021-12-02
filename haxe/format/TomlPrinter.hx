package haxe.format;

class TomlPrinter {

	static public function print(object : Dynamic) {
		printTable(object, [], true);
	}

	static private function printTable(object : Dynamic, path : Array<String>, ?colors : Bool = false) {
		var keys = Reflect.fields(object);

		var subtables = [];

		var tablevalues = [];
		
		for (k in keys) {
			var subval = Reflect.getProperty(object, k);
			if (Reflect.isObject(subval) 
			&& !Std.isOfType(subval, String) 
			&& !Std.isOfType(subval, Array)) {
				subtables.push({
					key: k,
					table: subval,
				});
			} else {
				var key = '$k';
				var value = '$subval';
				if (colors) {
					key = white(key);
					value = byType(subval);
				}
				if (Std.isOfType(subval, String)) value = "\"" + value + "\"";

				tablevalues.push('$key = $value');
			}
		}

		if (path.length > 0 && tablevalues.length > 0) {
			var title = path.join(".");
			if (colors) title = cyan(title, true);
			Sys.println('[$title]');
			for (tv in tablevalues) Sys.println(tv);
			Sys.println("");
		}

		for (st in subtables) {
			path.push(st.key);
			printTable(st.table, path, colors);
		}

		// removes this from the path. 
		path.pop();

	}

	///////////////////////////////////////
	// COLORS DUMP

	inline static private var BLACK : String = '\033[30m';
	inline static private var RED : String = '\033[31m';
	inline static private var GREEN : String = '\033[32m';
	inline static private var YELLOW : String = '\033[33m';
	inline static private var BLUE : String = '\033[34m';
	inline static private var MAGENTA : String = '\033[35m';
	inline static private var CYAN : String = '\033[36m';
	inline static private var WHITE : String = '\033[37m';

	inline static private var BRIGHTBLACK : String = '\033[30;1m';
	inline static private var BRIGHTRED : String = '\033[31;1m';
	inline static private var BRIGHTGREEN : String = '\033[32;1m';
	inline static private var BRIGHTYELLOW : String = '\033[33;1m';
	inline static private var BRIGHTBLUE : String = '\033[34;1m';
	inline static private var BRIGHTMAGENTA : String = '\033[35;1m';
	inline static private var BRIGHTCYAN : String = '\033[36;1m';
	inline static private var BRIGHTWHITE : String = '\033[37;1m';

	inline static private var RESET : String = '\033[0m';

	inline private static function make(color : String, text : Dynamic) : String return '${color}${text}${RESET}';

	inline public static function black(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTBLACK; } else { BLACK; }, text);
	inline public static function red(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTRED; } else { RED; }, text);
	inline public static function green(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTGREEN; } else { GREEN; }, text);
	inline public static function yellow(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTYELLOW; } else { YELLOW; }, text);
	inline public static function blue(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTBLUE; } else { BLUE; }, text);
	inline public static function magenta(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTMAGENTA; } else { MAGENTA; }, text);
	inline public static function cyan(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTCYAN; } else { CYAN; }, text);
	inline public static function white(text : Dynamic, ?bright : Bool = false) : String return make(if (bright) { BRIGHTWHITE; } else { WHITE; }, text);

	inline public static function category(string : String) : String {
		return switch(string) {
			case "log": blue(string);
			case "error": red(string);
			case "fault": red(string, true);
			case "warning": yellow(string);
			case "unimplemented": red(string);
			case _: string; 
		}
	}

	/**
	 * sets the color of the object string
	 */
	inline public static function byType(object : Dynamic) : String {

		var string = '${object}';
		// determines what color to print it as.
		if (object == null) string = magenta(string, true);
		else if (Std.isOfType(object, Int)) string = cyan(string);
		else if (Std.isOfType(object, Bool)) string = green(string);
		else if (Std.isOfType(object, Float)) string = yellow(string);
		else if (Std.isOfType(object, String)) string = red(string);
		else if (Type.getEnum(object) != null) string = yellow(string);
		else if (Std.isOfType(object, Array)) {
			string = "[";
			for (item in cast(object, Array<Dynamic>)) {
				string += byType(item) + ", ";
			}
			string = string.substr(0, string.length - 2) + "]";
		} else if (Type.getClass(object) != null) string = magenta(string);
		else {
			// assuming its a dynamic key, value object.
			
			string = "{";
			for (field in Reflect.fields(object)) {
				string += magenta(field) + ": " + byType(Reflect.getProperty(object, field)) + ", ";
			}
			string = string.substr(0, string.length - 2) + "}";
		}

		return string;
	}

}