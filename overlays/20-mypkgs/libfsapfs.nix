{stdenv, lib, autoreconfHook, pkg-config, zlib, openssl, osxfuse}:

stdenv.mkDerivation rec {
  pname = "osxutils";
  version = "2021-09-01";
/*
  src = fetchFromGitHub {
    owner = "libyal";
    repo = pname;
    rev = "c913629c0c14180f115f74313250e770f911ca46";
    sha256 = "1fgcv2g4w5gr2dfx472izry8gnglss2vj4q2yw44j9sbck6r3xsh";
  };
*/
  src = builtins.fetchurl {
    url = "https://github.com/libyal/libfsapfs/releases/download/20210424/libfsapfs-experimental-20210424.tar.gz";
    sha256 = "0vr2a65yymsy5i9smzysgdbx65lb5yvmrlh0i8gvj6qs0hr08bwx";
  };

  buildInputs = [ autoreconfHook pkg-config zlib openssl osxfuse ];
  preConfigure = [ "autoconf" ];
# configureFlags = [ "--prefix=${placeholder "out"}" ];
  
  meta = with lib; {
    description = "Library and tools to access the Apple File System";
    homepage = "https://github.com/libyal/libfsapfs";
    license = licenses.lgpl3;
    platforms = platforms.darwin;
  };
}
