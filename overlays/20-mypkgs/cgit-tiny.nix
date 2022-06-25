# no python, no lua, no dylibs. small closure great chroot, good cool, a nice

{ lib, stdenv, fetchurl, openssl, zlib, asciidoc, libxml2, libxslt
, docbook_xsl, pkg-config
, coreutils, gnused, docutils
, gzip, bzip2, lzip, xz, zstd
, cgit
}: let
  zstd-noscripts = zstd.overrideAttrs (_: {
    pname = "zstd-noscripts";
    postInstall = ''
      rm $bin/bin/zstd{grep,less}
    '';
  });
in stdenv.mkDerivation rec {
  pname = "cgit-tiny";

  inherit (cgit) version src gitSrc meta stripDebugList;

  nativeBuildInputs = [ pkg-config asciidoc ];
  buildInputs = [ openssl zlib libxml2 libxslt docbook_xsl ];
  outputs = [ "bin" "out" ];
  
  postPatch = ''
    sed -e 's|"gzip"|"${gzip}/bin/gzip"|' \
        -e 's|"bzip2"|"${bzip2.bin}/bin/bzip2"|' \
        -e 's|"lzip"|"${lzip}/bin/lzip"|' \
        -e 's|"xz"|"${xz.bin}/bin/xz"|' \
        -e 's|"zstd"|"${zstd-noscripts}/bin/zstd"|' \
        -i ui-snapshot.c
    sed -i 's|a2x|a2x --no-xmllint|' Makefile
  '';

  # Give cgit a git source tree
  preBuild = ''
    mkdir -p git
    tar --strip-components=1 -xf "$gitSrc" -C git
  '';

  makeFlags = [
    "NO_LUA=1"
    "prefix=$(out)"
    # grotesque. tldr this is something otherwise set inside the git makefile
    # and it's our means of preventing libgit.a from containing a reference to
    # $out. the semantics of that reference apply to $bin in our case if
    # anything, though i highly doubt that anything cgit ever does reaches
    # that code path. bleh
    "prefix_SQ=$(bin)"
    "CGIT_SCRIPT_PATH=$(bin)/cgit"
    "NO_REGEX=NeedsStartEnd"
    "CC=${stdenv.cc.targetPrefix}cc"
    "AR=${stdenv.cc.targetPrefix}ar"
  ];
  
  installTargets = [ "install" "install-man" ];
  
  stripDebugFlags = "--strip-unneeded";
}