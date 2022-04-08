package toml.parser;

import result.Result;
using toml.token.TokenArrayTools;

/**
 * A working class that helps build the data structure
 */
class Context {
	public var object : Dynamic;
	private var context : Dynamic;

	/**
	 * a list of tables created by setting the context.
	 *
	 * need to track this because we cannot define the same
	 * table twice, and I don't exactly have a way to check this
	 * without tracking this (or at least can't think of one now)
	 *
	 * should track this kind of case (this is not valid TOML):
	 * ```toml
	 * [a]
	 * b = 10
	 *
	 * [a]
	 * c = 11
	 * ```
	 */
	private var tablesCreated : Array<String> = [];

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
					else {
						// we already have an array here.
						var array = cast(existing, Array<Dynamic>);
						if (array.length == 0) return Error('array has already been defined, cannot redefine');
						array.push(newworking);
					}
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
		// OPTIMIZE: this function is a mess, need to rewrite it and clean it up

		// HACK: a var to store if we might be redefining a variable.
		// originally i would just record all 'context changes' and then error if the
		// same context change was attempted, but you can add items to an array by calling
		// the same name, and then access that array members using the same name .. so it will
		// normally error. the idea is to then set this flag and then check if anything new
		// was created trying to get to that context. if nothing new was created then we error,
		// if we make something new then this is unique and we are not accessing an already created
		// area of the object.
		var potentialRedefine : Bool = false;

		var working = if(context == null) {
			// checking if we already tried to set this context in the TOML
			// file, meaning we already defined this table somewhere.
			var string = toml.token.TokenArrayTools.toString(keys);
			if (tablesCreated.contains(string)) potentialRedefine = true;
			else tablesCreated.push(string);	
			this.context;
		} else context;

		var trimmed = keys.trim();
		var i = -1;
		var lastTokenIndex = 0; // added this because we could place arbitrary spaces around here.

		// HACK: added -1 to the while look
		// not sure why. perhaps its because we are doing the i++ inside the loop
		// but i wouldn't think that woudl matter. if we get ride of the -1 then
		// we get access errors (out of range) in the following switch
		while((i++) < trimmed.length-1) switch(trimmed[i].token) {

			case Word(text):
				// checking to make sure it was preceded by a `.` if it is not the first one.
				if (i != 0 && trimmed[lastTokenIndex].token != Period) return Error('malformed table name');

				lastTokenIndex = i;

				var existingValue = Reflect.getProperty(working, text);
				working = if (existingValue != null) {
					// we already exists, first we check if it is a table or not.
					//if (i == trimmed.length - 1) return Error('cannot define table key more than once');
					if (Type.typeof(existingValue) == TObject) existingValue;
					else if (Std.isOfType(existingValue, Array)) {
						// if we are indexing an array, then there shouldn't be an issue with redefining it,
						// except if this is the last part of the set, which means we are redefining it.
						if (i == trimmed.length - 1) potentialRedefine = true; // changed something
						var a = cast (existingValue, Array<Dynamic>);
						if (a.length == 0) a.push({});
						a[a.length-1];
					}
					else return Error('cannot redefine table key type');
				} else {
					potentialRedefine = false; // changed something
					// the key doesn't exist in this context, so we need to make it.
					var newWorking = { };
					Reflect.setProperty(working, text, newWorking);
					newWorking;
				};
				
				// checking that the key is an object or an array, so that we know we can actually set the
				// the context here
				if (Type.typeof(working) != TObject || Std.isOfType(working, Array))
					return Error('cannot set value because not an object');

			case Space(_):

			case Period:
				// checking that the table name formatting is correct
				if (i == 0 || trimmed[lastTokenIndex].token == Period) return Error ('malformed table name');
				lastTokenIndex = i;

			case SingleQuote | DoubleQuote:
				var insides : Array<toml.token.Metadata> = [];
				var offset = 0;
				while (i+(offset++) < trimmed.length && trimmed[i+offset].token != trimmed[i].token)
					insides.push(trimmed[i+offset]);
				if (i+offset == trimmed.length) return Error("could not find ending quote");
				var text = toml.token.TokenArrayTools.toString(insides);
				i += offset;

				lastTokenIndex = i;

				var existingValue = Reflect.getProperty(working, text);
				working = if (existingValue != null) {
					// we already exists, first we check if it is a table or not.
					if (Type.typeof(existingValue) == TObject) existingValue;
					else {
						return Error('cannot redefine table key type-1');
					}
				} else {
					// the key doesn't exist in this context, so we need to make it.
					var newWorking = { };
					Reflect.setProperty(working, text, newWorking);
					newWorking;
				};
				
				// checking that the key is an object or an array, so that we know we can actually set the
				// the context here
				if (Type.typeof(working) != TObject || Std.isOfType(working, Array))
					return Error('cannot set value because not an object');

			default:
				return Error("not implemented-set");
		}

		// if we haven't created anything new while going through this context,
		// then we need to error because we are re--accessing an already defined
		// area of the object.
		if (potentialRedefine) return Error('cannot redefine table key');

		// ensure we update the item's context.
		if (context == null) this.context = working;
		return Ok(working);
	}

	/**
	 * checks if the provided key is valid TOML key
	 */
	private function validateKeys(keys : Array<toml.token.Metadata>) : Bool {
		keys = keys.trim();
		for (i in 0 ... keys.length) {
			// makes sure we have items that are separated by periods.
			if (i%2 == 1 && keys[i].token != Period) return false;
			else switch(keys[i].token) {
				case Word(string):
					// checking that we only have approved characters.
					for (c in 0 ... string.length) {
						var char = string.charCodeAt(c);
						if ((48 <= char && char <= 57) // 0-9
						|| (65 <= char && char <=90) // A-Z
						|| (97 <= char && char <= 122) // a-z
						|| (char == 95) // _
						|| (char == 45)) { //-

						} else {
							return false;
						}
					}

				default: return false; // HACK: maybe?
			}
		}

		return true;
	}
}
