{
  stdenv, lib, fetchFromGitHub,
  curl, sqlite, tcl,
  CoreFoundation, SystemConfiguration, IOKit
}: stdenv.mkDerivation rec {
  pname = "daemondo";
  version = "2.7.2";

  buildInputs = [
    curl sqlite tcl
    CoreFoundation SystemConfiguration IOKit
  ];

  src = fetchFromGitHub {
    owner = "macports";
    repo = "macports-base";
    rev = "v${version}";
    sha256 = "0bhjcc0qz5b297p087x55ldfz8jm4b2ndns989rm5b8cp4zwlxpz";
  };

  preBuild = "cd src/programs/daemondo";
  installPhase = ''
    mkdir -p $out/bin
    mv build/daemondo $out/bin/
  '';

  meta = with lib; {
    description = "Wrapper for daemons to play nice with launchd";
    homepage = "https://github.com/macports/macports-base/tree/master/src/programs/daemondo";
    license = licenses.bsd3;
    platforms = platforms.darwin;
    maintainers = [ maintainers.ylh ];
  };
}
