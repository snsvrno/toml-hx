class Main {
	public static function main() {
		var args = Sys.args();

		var content = toml.Toml.tryLoad(args);
		toml.Printer.print(content);
	}
}