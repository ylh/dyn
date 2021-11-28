{ stdenv, fetchFromGitHub, python37 }: stdenv.mkDerivation rec {
  pname = "iterm2-shell-integration";
  version = "2021-10-28";
  src = fetchFromGitHub {
    owner = "gnachman";
    repo = "iTerm2-shell-integration";
    rev = "6663e257ea68e76d4b926e5b970065c7551096b7";
    sha256 = "cJgB3R9qiao74PifgLgQRTmvgp0QNHAiEzVqN4XAmrM=";
  };

  nativeBuildInputs = [ python37 ];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp shell_integration/{ba,fi,tc,z}sh $out/
    cp utilities/* $out/bin/
  '';
}
