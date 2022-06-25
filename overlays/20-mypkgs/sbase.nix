{ lib, stdenv, fetchgit, ed }:
assert stdenv.hostPlatform.isStatic;
stdenv.mkDerivation rec {
  pname = "sbase";
  version = "2022-06-20";

  src = fetchgit {
    url = "git://git.suckless.org/sbase";
    rev = "63271b47f7e045cdee3fa90178560f982b70c218";
    sha256 = "0zra49ad2ajq26vidqxaxdx2l2xrzn4f27il0x2z8gznm3j77ppw";
  };

  nativeBuildInputs = [ ed ];

  postPatch = ''
    ed -s config.mk <<EOF
    /^PREFIX/s,/usr/local,$out,
    /^CC/s,cc,$CC,
    /^AR/s,ar,$AR,
    /^RANLIB/s,ranlib,$RANLIB,
    /LDFLAGS/d
    wq
    EOF
  '';

  dontConfigure = true;

  meta = with lib; {
    description = "suckless unix tools";
    homepage = "http://git.suckless.org/sbase/";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.ylh ];
  };
}
