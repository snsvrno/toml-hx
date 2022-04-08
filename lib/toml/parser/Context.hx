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
		if (!validateKeys(key)) return "not a valid key";

		var trimmed = key.trim();
		var finalkey = trimmed.pop();

		switch(set(trimmed, context)) {
			
			case Error(msg):
				return msg;
			
			case Ok(localcontext):
				switch(finalkey.token) {

					case Word(text):
						// need to check if this is already set
						var existingValue = Reflect.getProperty(localcontext, text);
						if (existingValue != null) {
							// TODO: check that this value is the same type / kind as the value we are setting
							// normal spec doesn't allow to reset a value, so on a single file (or if we are following
							// the TOML spec exactly) we should error here and not need to do the check.
							return 'cannot set value because already set.';
						}
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
	 * moves the context inside an array
	 *
	 * @param key the tokens that make up the key
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
		for (i in 0 ... trimmed.length) switch(trimmed[i].token) {
			case Word(text):
				// checking to make sure it was preceded by a `.` if it is not the first one.
				if (i != 0 && trimmed[i-1].token != Period) return Error('malformed table name');

				working = if (Reflect.hasField(working, text) && i < trimmed.length - 1) {
					Reflect.getProperty(working, text);
				} else if (Reflect.hasField(working, text)) {
					// we have the field, but we are at the end of setting the context.
					// per TOML spec we are not allowed to have a definition for the same
					// object in multiple places.
					return Error('cannot redefine object');
				} else {
					var newworking = { };
					Reflect.setProperty(working, text, newworking);
					newworking;
				};
				
				// checking that the key is an object or an array, so that we know we can actually set the
				// the context here
				if (Type.typeof(working) != TObject || Std.isOfType(working, Array))
					return Error('cannot set value because not an object');

			case Period:
				// checking that the table name formatting is correct
				if (i == 0 || trimmed[i-1].token == Period) return Error ('malformed table name');

			default:
				return Error("not implemented-set");
		}

		// ensure we update the item's context.
		if (context == null) this.context = working;
		return Ok(working);
	}

	/**
	 * checks if the provided key is valid TOML key
	 */
	private function validateKeys(keys : Array<toml.token.Metadata>) : Bool {
		for (i in 0 ... keys.length) {
			if (i%2 == 1 && keys[i].token != Period) return false;
		}

		return true;
	}
}
