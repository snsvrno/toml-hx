package toml;

class Toml {

    static public function parse(content : String, ?source : String) : Dynamic {
        var lexer = new toml.lexer.Lexer(content, source);
        lexer.run();

        var parser = lexer.toParser();
        parser.run();

        return parser.object;
    }

    static public function load(files : Array<String>) : Dynamic {
        var parser : Null<toml.parser.Parser> = null;

		for (file in files) {

			var content = sys.io.File.getContent(file);

            if (parser != null) parser.parse(content, file);
            else {

                var lexer = new toml.lexer.Lexer(content, file);
                lexer.run();

                parser = lexer.toParser();
                parser.run();
            }
			
		}

		return parser.object;
    }

    #if result
    static public function tryLoad(files : Array<String>) : Dynamic {
        return load(files);
    }
    #end
}