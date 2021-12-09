// builds the test decoder to work with TOML-TEST

class Decoder {
	public static function main() {
		

		// will be the test string, provided via STDIN by TOML-TEST
		var text : String = "";

		// capture the input.
		try { while (true) text += Sys.stdin().readLine() + "\n"; }
		catch (e:haxe.io.Eof) {

			// now attempt to parse it.
			try {
				var toml = toml.Toml.parse(text);
				
				// provide a JSON string for the TOML-TEST to confirm
				// it was parsed correctly.
				var string = haxe.Json.stringify(toml);
				Sys.println(string);

				// if we are here then we successfully parsed it, end of a success.
				Sys.exit(0);
			} 

			// if we throw anything then we quit on a failure.
			catch (_) Sys.exit(1);
			
		}
	
	}
}