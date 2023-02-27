{ stdenv, fetchFromGitHub, python38 }: stdenv.mkDerivation rec {
  pname = "iterm2-shell-integration";
  version = "2023-02-12";
  src = fetchFromGitHub {
    owner = "gnachman";
    repo = "iterm2-shell-integration";
    rev = "a837722a3ba413bcf9cb73f1ffd1b0bd4b9f183e";
    sha256 = "c1LWcQtl6rPoJ8uYh3+Cvd1g+1/daqtqt1eKPmFkjnI=";
  };

  nativeBuildInputs = [ python38 ];
  dontConfigure = true;
  dontBuild = true;
  dontPatchShebangs = true;
  dontStrip = true;
  installPhase = ''
    mkdir -p $out/bin
    cp shell_integration/{ba,fi,tc,z}sh $out/
    cp utilities/* $out/bin/
  '';
  postFixup = ''
  	patchShebangs $out/bin
  '';
}
