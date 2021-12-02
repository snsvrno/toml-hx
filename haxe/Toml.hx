package haxe;

class Toml {

	inline static public function parse(text : String) : Dynamic {
		return haxe.format.TomlParser.parse(text);
	}

}