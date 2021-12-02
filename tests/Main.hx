class Main {
	public static function main() {
		var content = sys.io.File.getContent("test/file.toml");
		var item = haxe.Toml.parse(content);
		haxe.format.TomlPrinter.print(item);
	}
}