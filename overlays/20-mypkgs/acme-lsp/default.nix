{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "acme-lsp";
  version = "2022-05-03";

  src = fetchFromGitHub {
    owner = "fhs";
    repo = pname;
    rev = "f95a8c546675204b20be5e52bd747f2e20fda308";
    sha256 = "1ycd20myyg7434ycg8ahihydgb4byq1gm0qqxc2p09j793yskvxg";
  };

  vendorSha256 = "1a99759x8jccajrral65d8s4cc9yn68qg56k3qm676vb2v0mfalv";

  doCheck = false; # wants pyls which we can't build
}