package haxe.format;

#if termcolors
import termcolors.Termcolors.*;
#end

class TomlPrinter {

	static public function print(object : Dynamic) {
		printTable(object, []);
	}

	static private function printTable(object : Dynamic, path : Array<String>) {
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
				
				#if termcolors
				// colors the text if we have the library loaded.
				key = white(key);
				value = byType(subval);
				#end

				if (Std.isOfType(subval, String)) value = "\"" + value + "\"";

				tablevalues.push('$key = $value');
			}
		}

		if (path.length > 0 && tablevalues.length > 0) {
			var title = path.join(".");
			
			#if termcolors 
			// colors the text if we have the library loaded.
			title = cyan(title, [Bold]);
			#end

			Sys.println('[$title]');
			for (tv in tablevalues) Sys.println(tv);
			Sys.println("");
		}

		for (st in subtables) {
			path.push(st.key);
			printTable(st.table, path);
		}

		// removes this from the path. 
		path.pop();
	}
}