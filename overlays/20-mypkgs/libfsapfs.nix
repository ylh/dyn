{stdenv, lib, fetchFromGitHub, autoreconfHook, pkg-config, zlib, openssl, macfuse-stubs, libfuse}:

stdenv.mkDerivation rec {
  pname = "libfsapfs";
  version = "2021-09-01";

  src = fetchFromGitHub {
    owner = "libyal";
    repo = pname;
    rev = "11c961ff4379d0317ea6748f984e996f816ded12";
    sha256 = "06dsdbd2lm47rn9yb134yvfh9dsgcm5y9dnd2pp8zwv1nsddb2q1";
  };

  buildInputs = [ autoreconfHook pkg-config zlib openssl (
    if stdenv.isDarwin then
      macfuse-stubs
    else
      libfuse
  ) ];
  preConfigure = [ "autoconf" ];

  meta = with lib; {
    description = "Library and tools to access the Apple File System";
    homepage = "https://github.com/libyal/libfsapfs";
    license = licenses.lgpl3;
    platforms = [ platforms.darwin platforms.linux ];
    maintainers = [ maintainers.ylh ];
  };
}
