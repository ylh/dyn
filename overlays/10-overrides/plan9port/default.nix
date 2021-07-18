self: super: let
	lib = super.lib;
in super.plan9port.overrideAttrs ({meta, src, ...}: assert (
	# these patches miiiight break if upstream does something spicy
	src.outputHash == "sha256-HCn8R9YSocHrpw/xK5n8gsCLSAbAQgw0NtjO9vYIbKo="); {
	"meta" = lib.filterAttrs (n: _v: n != "broken") meta;
	patches = [
		./acme-backport-9front-spacesindent.patch
		./pwd-import-from-4e.patch
		./fontsrv-leave-vanity-behind.patch
	];
})