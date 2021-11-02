{
  stdenv, lib, fetchFromGitHub,
  curl, sqlite, tcl,
  CoreFoundation, SystemConfiguration, IOKit
}: stdenv.mkDerivation rec {
  pname = "daemondo";
  version = "2.7.1";
  

  buildInputs = [
    curl sqlite tcl
    CoreFoundation SystemConfiguration IOKit
  ];

  src = fetchFromGitHub {
    owner = "macports";
    repo = "macports-base";
    rev = "v${version}";
    sha256 = "1bglmkzil2j6icqn4wr0wqb1sw36fn57ipz50h28zl22yasaprs2";
    fetchSubmodules = true;
  };
  
  preBuild = "cd src/programs/daemondo";
  installPhase = ''
    mkdir -p $out/bin
    mv build/daemondo $out/bin/
  '';
}
