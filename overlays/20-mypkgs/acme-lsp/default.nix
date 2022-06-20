{ buildGoApplication, fetchFromGitHub}:
buildGoApplication rec {
  pname = "acme-lsp";
  version = "2022-05-03";

  src = fetchFromGitHub {
    owner = "fhs";
    repo = pname;
    rev = "f95a8c546675204b20be5e52bd747f2e20fda308";
    sha256 = "1ycd20myyg7434ycg8ahihydgb4byq1gm0qqxc2p09j793yskvxg";
  };
  modules = ./gomod2nix.toml;

  doCheck = false; # wants pyls which we can't build
}
