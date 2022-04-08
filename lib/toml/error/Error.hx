package toml.error;

typedef Error = {
	token : toml.token.Metadata,
	message: String,
};
