package toml.parser;

import result.Result;
using toml.token.TokenArrayTools;

/**
 * A working class that helps build the data structure
 */
class Context {
	public var object : Dynamic;
	private var context : Dynamic;

	public function new() {
		object = { };
		context = object;
	}

	/**
	 * Sets a value within the current context
	 *
	 * Returns null on a sucessful set.
	 *
	 * @param key the tokens that make up the key
	 * @param value the actual final value for the key
	 * @return an error message if there is an issue with setting the value
	 */
	public function setValue(key : Array<toml.token.Metadata>, value : Dynamic) : Null<String> {
		var trimmed = key.trim();
		var finalkey = trimmed.pop();

		switch(set(trimmed, context)) {
			
			case Error(msg):
				return msg;
			
			case Ok(localcontext):
				switch(finalkey.token) {

					case Word(text): 
						Reflect.setProperty(localcontext, text, value);
						return null;
	
					default:
						return "error";
				}
		}

	}

	/**
	 * Moves the context back to the root of the data structure
	 */
	public function reset() {
		context = object;
	}

	/**
	 * sets a key value where that key is defined as an array
	 *
	 * The resulting data structure @ `key` is an array, and `value`
	 * will be pushed into that array.
	 *
	 * Returns null on a sucessful set.
	 *
	 * @param key the tokens that make up the key
	 * @param value the actual final value for the key
	 * @return an error message if there is an issue with setting the value
	 */
	public function setArray(keys : Array<toml.token.Metadata>, ?context : Dynamic) : Result<Dynamic, String> {
		var working : Dynamic = if(context == null) this.context;
		else context;

		var trimmed = keys.trim();
		var lastkey = trimmed.pop();
		
		switch(set(trimmed, working)) {
			case Error(err): return Error(err);
			case Ok(ctx): working = ctx;
		}

		switch(lastkey.token) {
			case Word(text):
				var newworking = { };
				if (Reflect.hasField(working, text)) {
					var existing = Reflect.getProperty(working, text);
					if (Std.isOfType(existing, Array) == false) return Error('expected an array, found "$existing" instead');
					cast(existing, Array<Dynamic>).push(newworking);
				} else {
					Reflect.setProperty(working, text, [newworking]);
				};
				working = newworking;

			default:
				return Error("not implemented-setarray");

		}

		// ensure we update the item's context.
		if (context == null) this.context = working;
		return Ok(working);
	}

	/**
	 * moves the context without setting a value
	 *
	 * Moves into keys on the data struture, creating keys if they don't exist.
	 *
	 * @param key the tokens that make up the key
	 * @return the resulting context on a sucess, or an error message if there is an issue
	 */
	public function set(keys : Array<toml.token.Metadata>, ?context : Dynamic) : Result<Dynamic, String> {
		var working = if(context == null) this.context;
		else context;

		var trimmed = keys.trim();
		for (t in trimmed) switch(t.token) {
			case Word(text):
				working = if (Reflect.hasField(working, text)) {
					Reflect.getProperty(working, text);
				} else {
					var newworking = { };
					Reflect.setProperty(working, text, newworking);
					newworking;
				};
				// TODO: check that this working is actually a dictonary if we are not at the last key item.

			case Period:
				// TODO: need to do some kind of checking here.

			default:
				return Error("not implemented-set");
		}

		// ensure we update the item's context.
		if (context == null) this.context = working;
		return Ok(working);
	}
}
