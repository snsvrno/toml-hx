package toml.token;

class MetadataTools {

	public static function toError(token : Metadata, msg : String) : toml.error.Error {
		return {
			token: token,
			message: msg,
		};
	}
}
