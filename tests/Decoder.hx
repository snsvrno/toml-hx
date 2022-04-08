// builds the test decoder to work with TOML-TEST

import toml.Toml;

class Decoder {
	public static function main() {
		

		// will be the test string, provided via STDIN by TOML-TEST
		var text : String = "";

		// capture the input.
		try { while (true) text += Sys.stdin().readLine() + "\n"; }
		catch (e:haxe.io.Eof) switch(Toml.parse(text)) {
			case Error(error):

				Sys.stderr().writeString(error);
				Sys.exit(1);

			case Ok(data):

				// provide a JSON string for the TOML-TEST to confirm
				// it was parsed correctly.
				TestTools.jsonTtype(data);
				var string = haxe.Json.stringify(data);
				Sys.println(string);

				// if we are here then we successfully parsed it, end of a success.
				Sys.exit(0);
		}
	
	}
}
