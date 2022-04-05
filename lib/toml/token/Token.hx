package toml.token;

enum Token {
	Hash;
	LeftMoustache; RightMoustache;
	LeftBracket; RightBracket;
	SingleQuote; DoubleQuote;
	Equals;
	Period;
	Comma; Colon; SemiColon;

	Space(length : Int);
	Tab(count : Int);
	Word(text : String);
	EOL;

	// for custom type handling
	// TODO: put a reference to the point in the wiki or manual that describes this.
	LeftArrow; RightArrow;
}
