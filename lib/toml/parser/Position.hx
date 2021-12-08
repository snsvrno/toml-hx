package toml.parser;

typedef Position = {
    lines : Array<String>,
    file : Null<String>,
    line : Int,
    column : Int,

    errorLength: Int,
};