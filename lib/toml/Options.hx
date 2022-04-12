package toml;

enum Options {
	/*** allow the ability to overwrite values that change the inherit type of the value */
	AllowDifferentTypes;

	/*** when merging error on merging that creates new keys */
	PreventNewFields;

	/*** when loading folders, look in all subfolders **/
	Recursive;
}
