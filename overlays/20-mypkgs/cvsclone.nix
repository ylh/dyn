{ stdenv, lib, fetchurl, flex, ... }: stdenv.mkDerivation rec {
  pname = "cvsclone";
  version = "2017-02-13";

  src = fetchurl {
    url = "https://repo.or.cz/cvsclone.git/snapshot/503936d9f8633c50dc3a1a9b35082f7b66c59c6e.tar.gz";
    sha256 = "1x986cv31rbj7iq9y1dnq8ylqk7an620bfg20rs8msr4gg6dnhl2";
  };
  buildInputs = [ flex ];
  prePatch = "sed -i 's/gcc/\${CC}/' Makefile";

  dontConfigure = true;
  installPhase = ''
    mkdir -p $out/bin
    cp ${pname} $out/bin/
  '';

  meta = with lib; {
    homepage = "https://repo.or.cz/w/cvsclone.git";
    description = "Quick CVS repository leecher";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
  };
}
