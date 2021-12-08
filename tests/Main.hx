class Main {
	public static function main() {
		var args = Sys.args();

		var content = haxe.Toml.tryLoad(args);
		haxe.format.TomlPrinter.print(content);
	}
}