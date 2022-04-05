package toml;

function load(path : String) : Array<haxe.macro.Expr.Field> {
	var fields = haxe.macro.Context.getBuildFields();

	var content = sys.io.File.getContent(path);
	switch(toml.Toml.parse(content)) {
		case Error(msg): throw msg;
		case Ok(parsed):

			var tfields = Reflect.fields(parsed);
			for (f in tfields) {
				var value = Reflect.getProperty(parsed, f);
				fields.push({
					name: f,
					pos: haxe.macro.Context.currentPos(),
					access: [AStatic, APublic],
					kind: FVar(null, macro $v{value}),
				});
			}

			fields.push({
				name: "loadFile",
				pos: haxe.macro.Context.currentPos(),
				access: [AStatic, APublic],
				kind: FFun({
					args: [{ name : "paths", type : macro : ... String, }],
					expr: macro {
						for (p in paths) {
							if (sys.FileSystem.exists(p)) throw 'path $p does not exists';
							loadContent(sys.io.File.getContent(p));
						}
					},
				}),
			});
		
			var localclass = haxe.macro.Context.getLocalClass().get().name;

			fields.push({
				name: "loadContent",
				pos: haxe.macro.Context.currentPos(),
				access: [AStatic, APublic],
				kind: FFun({
					args: [
						{ name : "text", type : macro : String, },
						{ name : "source", type : macro : String, opt : true, },
					],
					expr: macro {
						switch(toml.Toml.parse(text, source)) {
							case Error(err): throw (err);
							case Ok(loaded):
								var flat = toml.Toml.flatten(loaded);
								for (k => v in flat) {
									var context : Dynamic = $i{localclass};
									var split = k.split(".");

									for (i in 0 ... split.length - 1) {
										var temp = Reflect.getProperty(context, split[i]);
										if (temp == null) {
											temp = { };
											Reflect.setProperty(context, split[i], temp);
										} else {
											// check if it is a data table
											if (Type.typeof(context) != TObject) throw ('is the wrong type!');
										}
										context = temp;
									}

									var olddata = Reflect.getProperty(context, split[split.length-1]);
									if (olddata == null) throw('$k does not exist, cannot write to fields that dont exist: $source');
									else if (Type.typeof(olddata) != Type.typeof(v)) throw ('$k from $source is a different type than origin: ${Type.typeof(olddata)} vs ${Type.typeof(v)}');
									Reflect.setProperty(context, split[split.length-1], v);

								}
						}
					},
				}),
			});

	}

	return fields;
}
