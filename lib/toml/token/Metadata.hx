package toml.token;

/**
 * A wrapper that contains more information about the token that us used for error handling
 */
typedef Metadata = {
	/*** the token */
	token : Token,
	/*** the starting position of the token */
	pos : Int,
	/*** the line of the token */
	line : Int,
};
