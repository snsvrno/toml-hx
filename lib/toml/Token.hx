package toml;

#if codesense
typedef Token = codesense.CodeSense<toml.lexer.Token>;
#else
typedef Token = toml.lexer.Token;
#end