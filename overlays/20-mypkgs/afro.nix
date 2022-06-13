{ buildPythonPackage, fetchFromGitHub
, numpy, colorlog, kaitaistruct
}:
buildPythonPackage rec {
  pname = "afro";
  version = "0.2";

  src = fetchFromGitHub {
    owner = "cugu";
    repo = pname;
    rev = "d24e7e1c722ba51f38bb7accbb171b33e3165b45";
    sha256 = "0khzwkhdh68hhc4v8ig2m2rm2vbzvjs085kl5fdl34dz4r9dvkn4";
  };

  propagatedBuildInputs = [ numpy colorlog kaitaistruct ];
}
