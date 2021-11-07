{stdenv, lib, fetchFromGitHub, argp-standalone}:

stdenv.mkDerivation rec {
  pname = "drat";
  version = "2021-10-08";

  src = fetchFromGitHub {
    owner = "TurtleARM";
    repo = "drat";
    rev = "ac919e20e81e0f16fb46e4fbc289caea426b1f98";
    sha256 = "1s0mxs79603dnxywizw74x4b694drdhpciyjn8lr3bagbw7h4bq1";
    fetchSubmodules = true;
  };
  makeFlags = [ "CC=${stdenv.cc.targetPrefix}cc" "LD=${stdenv.cc.targetPrefix}cc" ];
  installPhase = ''
    mkdir -p $out/bin
    cp drat $out/bin/
  '';
  buildInputs = [ argp-standalone ];
  configurePhase = [];
  meta = with lib; {
    description = "Utility for performing data recovery and analysis of APFS partitions/containers";
    homepage = "https://github.com/jivanpal/drat";
    license = licenses.lgpl3;
    platforms = platforms.darwin;
  };
}
