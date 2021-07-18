self: super: let
	special = {
		osxutils = {
			inherit (super.darwin.apple_sdk.frameworks) Carbon Cocoa;
		};
	};
	call = (n: v: super.callPackage v (special.${n} or {}));
in super.lib.hereFlatAttrsMap call ./.
