self: super: let
  lib = super.lib;
  lastby = sep: x: lib.last (lib.splitString sep x);
in super.plan9port.overrideAttrs (old@{meta, src, pname, ...}: rec {
  patches = [
    ./acme-backport-9front-spacesindent.patch
    ./pwd-import-from-4e.patch
    ./fontsrv-slightly-fudge-height-numbers.patch
    ./fontsrv-leave-vanity-behind.patch
  ];
#  version = lastby "=" (lastby "+" old.version);
#  name = "${pname}-${version}";
})
