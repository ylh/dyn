self: super: let
	lib = super.lib;
in super.plan9port.overrideAttrs ({meta, src, ...}:
	if lib.hasPrefix "70cc6e5b" src.rev then {
    meta = lib.filterAttrs (n: _v: n != "broken") meta;
    patches = [
		  ./acme-backport-9front-spacesindent.patch
		  ./pwd-import-from-4e.patch
		  ./fontsrv-leave-vanity-behind.patch
		];
	} else {}
)