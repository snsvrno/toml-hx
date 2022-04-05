# Toml-hx
A native [TOML](https://toml.io/) parser for haxe, works with all targets.

Designed to be compliant toml [v1.0.0](https://toml.io/en/v1.0.0) and have extensive warning / error handling. Tested with [toml-test](https://github.com/BurntSushi/toml-test)

## Development Setup

- haxe
- neko
- [toml-test](https://github.com/BurntSushi/toml-test) (for testing)

### Setting up Direnv

The original develop environment is setup using [direnv](https://direnv.net/) and is not required, but might be helpful (for unix platforms).

- **Haxe** is installed in `.haxe/$version`, with a file `.haxe/version` that dictates which version to use.
- **Neko** is installed in `.neko/$version`, with a file `.neko/version` that dictates which version to use.
- **toml-test** is installed in `.toml-test` by cloning the [toml-test](https://github.com/BurntSushi/toml-test) and following the instructions there to build it.

The `.envrc` then adds all of these to the local path, as well as adding the `.scripts` folder to the path for easy execution of builder and helper scripts

## Testing

### Running the Test Suite
This library uses [toml-test](https://github.com/BurntSushi/toml-test) to ensure compliance with the TOML spec. In order to run the tests you need to run `toml-test` with the decoder that is built using `hxmls/decoder.hxml`.

```bash
haxe hxmls/decoder.hxml
toml-test neko bin/decoder.n
```

This repo is setup for use with [direnv](https://direnv.net/), so if that is setup properly then instead you can just run the following...

```bash
run-tests
```

### Individual File Testing

If you want to test the parsing of a particular toml file you can use `hxmls/test.hxml`

```bash
haxe hxmls/test.hxml
neko bin/test.n path/to/file.toml
```

Or if [direnv](https://direnv.net) is setup

```bash
test-file path/to/file.toml
```
