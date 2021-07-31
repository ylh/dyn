{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "about-filter";
  version = "0.1.0";
  
  src = fetchFromGitHub {
    owner = "ylh";
    repo = pname;
    rev = version;
    sha256 = "1vr7vyx8bch3h3d6055d0d808z90agw36wwj98vfbwaayr1g6mag";
  };
  
  cargoSha256 = "0bdib01hkcv89wrmkc8d33vrfda6xx6drcxdhl2yh38bbszci8w7";
  
  meta = with lib; {
    description = "cgit-specific readme formatter multiplexer";
    homepage = "https://git.ylh.io/about-filter";
    license = licenses.isc;
  };
}
    