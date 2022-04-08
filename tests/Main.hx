class Main {
	public static function main() {
		var args = Sys.args();

		toml.Toml.registerEval("color",evalcolor);

		switch (toml.Toml.load(...args)) {
			case Ok(content):
				TestTools.jsonTtype(content);
				Sys.println(haxe.Json.stringify(content, "  "));// toml.Printer.print(content);
			case Error(e): Sys.println(e);
		}
		
	}

	public static function evalcolor(text : String) : Int {
		return 0xFF0000;
	}
}
