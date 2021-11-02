{stdenv, lib, fetchFromGitHub, perl, Carbon, Cocoa}:

stdenv.mkDerivation rec {
  pname = "osxutils";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "specious";
    repo = "osxutils";
    rev = "v${version}";
    sha256 = "1ik6h0k4kq37d4yrr4sg516rxhqzb9h1s8za9yjy4m48rqsqpw5k";
  };

  buildInputs = [ perl Carbon Cocoa ];
  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = with lib; {
    description = "A collection of MacOS X command line utilities, based on the original project by Sveinbjorn Thordarson";
    homepage = "https://github.com/specious/osxutils";
    license = licenses.gpl2;
    platforms = platforms.darwin;
  };
}