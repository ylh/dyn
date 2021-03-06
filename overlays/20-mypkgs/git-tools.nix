{ stdenv, lib, python, fetchFromGitHub, installShellFiles }:

stdenv.mkDerivation rec {
  pname = "git-tools";
  version = "2020.09";

  src = fetchFromGitHub {
    owner = "MestreLion";
    repo = pname;
    rev = "v${version}";
    sha256 = "03c4bdp49khdvsxr4j4kqam59c98pazra4hs8hfmwwck1hzifhg9";
  };

  nativeBuildInputs = [ installShellFiles ];

  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp git-* $out/bin/
    installManPage man1/*.1
  '';

  meta = with lib; {
    description = "Assorted git-related scripts (home of git-restore-mtime)";
    homepage = "https://github.com/MestreLion/git-tools/";
    license = lib.licenses.gpl3;
    platforms = platforms.unix;
    maintainers = [ maintainers.ylh ];
  };
}
