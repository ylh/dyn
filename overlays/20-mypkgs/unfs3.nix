{ fetchFromGitHub, lib, stdenv, autoconf, automake, pkg-config, flex, bison, libtirpc }:

stdenv.mkDerivation rec {
  pname = "unfs3";
  version = "2022-05-12";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "a7bd4ba0c228cca1dbc78b8bf4699107a3542eaa";
    sha256 = "19hfssiydk63bwxdw8y5n4pga5lki23wwwavvirr4ypsf3cqj2rj";
  };

  nativeBuildInputs = [ autoconf automake pkg-config flex bison ];
  buildInputs = [ libtirpc ];

  preConfigure = "./bootstrap";
  configureFlags = [ "--disable-shared" ];

  doCheck = false; # no test suite

  meta = {
    description = "User-space NFSv3 file system server";

    longDescription = ''
      UNFS3 is a user-space implementation of the NFSv3 server
      specification.  It provides a daemon for the MOUNT and NFS
      protocols, which are used by NFS clients for accessing files on the
      server.
    '';

    homepage = "http://unfs3.github.io/";

    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
}
