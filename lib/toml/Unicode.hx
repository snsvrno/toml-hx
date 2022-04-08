package toml;

// OPTIMIZE: this whole thing, needs a refactor to make it good and clean.
class Unicode {

	// https://unicode.org/glossary/#unicode_scalar_value
	public static function isScalar(hex : String) : Bool {
		var code = hexToInt(hex);
		if ((0 <= code && code <= 0xD7FF )||(0xE000 <= code && code <= 0x10FFFF)) return true;
		else return false;
	}

	// the intent is to take hex escape code from a string, and return
	// the unicode symbol for that escape
	public static function fromHex(hex : String) : String {
		var int = hexToInt(hex);
		if (0 <= int && int <= 0x007F) {
			// one byte
			var bytes = haxe.io.Bytes.alloc(1);
			bytes.set(0, int);
			return bytes.getString(0,1);
		

		} else if (0x0080 <= int && int <= 0x07FF) {
			// two bytes
			var binary = hexToBin(hex);

			var chunk1 = "110" + binary.substr(binary.length-11,5);
			var chunk2 = "10" + binary.substr(binary.length-6,6);

			var bytes = haxe.io.Bytes.alloc(2);

			bytes.set(0, hexToInt(binToHex(chunk1)));
			bytes.set(1, hexToInt(binToHex(chunk2)));
			return bytes.getString(0,2);

		} else if (0x0800 <= int && int <= 0xFFFF) {
			// three bytes
			var binary = hexToBin(hex);

			var chunk1 = "1110" + binary.substr(binary.length-16,4);
			var chunk2 = "10" + binary.substr(binary.length-12,6);
			var chunk3 = "10" + binary.substr(binary.length-6,6);

			var bytes = haxe.io.Bytes.alloc(3);

			bytes.set(0, hexToInt(binToHex(chunk1)));
			bytes.set(1, hexToInt(binToHex(chunk2)));
			bytes.set(2, hexToInt(binToHex(chunk3)));

			return bytes.getString(0,3);

		} else {
			// four bytes
			throw('unimplemented');

		}

		return hex;
	}

	inline private static function hexToInt(hex : String) : Int {
		var i = hex.length;

		var int = 0;

		while((i-=1) >= 0) {
			var n = switch (hex.charAt(i).toLowerCase()) {
				case "0": 0;
				case "1": 1;
				case "2": 2;
				case "3": 3;
				case "4": 4;
				case "5": 5;
				case "6": 6;
				case "7": 7;
				case "8": 8;
				case "9": 9;
				case "a": 10;
				case "b": 11;
				case "c": 12;
				case "d": 13;
				case "e": 14;
				case "f": 15;
				default: 0;
			}

			int += Math.floor(Math.pow(16, hex.length-1-i) * n);

		}

		return int;
	}

	inline private static function hexToBin(hex : String) : String {
		var binary = "";

		for (i in 0 ... hex.length) {
			var n = switch (hex.charAt(i).toLowerCase()) {
				case "0": "0000";
				case "1": "0001";
				case "2": "0010";
				case "3": "0011";
				case "4": "0100";
				case "5": "0101";
				case "6": "0110";
				case "7": "0111";
				case "8": "1000";
				case "9": "1001";
				case "a": "1010";
				case "b": "1011";
				case "c": "1100";
				case "d": "1101";
				case "e": "1110";
				case "f": "1111";
				default: "";
			}

			binary += n;

		}

		return binary;

	}

	inline private static function binToHex(bin : String) : String {
		var hex = "";

		var i = 0;
		while (i < bin.length - 3) {
			var n = switch(bin.substr(i,4)) {
				case "0000": "0";
				case "0001": "1";
				case "0010": "2";
				case "0011": "3";
				case "0100": "4";
				case "0101": "5";
				case "0110": "6";
				case "0111": "7";
				case "1000": "8";
				case "1001": "9";
				case "1010": "A";
				case "1011": "B";
				case "1100": "C";
				case "1101": "D";
				case "1110": "E";
				case "1111": "F";

				default: "";
			}
			hex += n;

			i += 4;
		}

		return hex;
	}

}
