self: super:
with super.lib;
{
/*  git-fast-export = (super.git-fast-export.overrideAttrs (a@{ version, pname, ... }:
    assert (assertVersion a "200213");
    rec {
      version = "201029";
      src = super.fetchFromGitHub {
        owner = "frej";
        repo = pname;
        rev = "v${version}";
        sha256 = "08yjisqcixycbhm4hsfl5qp01scbcx2hsj7w6ps6i68d2n8l87c9";
      };
    }
  )).override { mercurial = self.mercurial; }; */
} // super.lib.hereFlatAttrsMap (n: f: f self super) ./.
