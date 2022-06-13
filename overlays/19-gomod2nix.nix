# mypkgs is cute/clever but gomod2nix provides an overlay that adds two terms
# to pkgs, gomod2nix and buildGoApplication. named before mypkgs so we can use
# the latter in there.
import "${builtins.fetchGit {
  url = "https://github.com/tweag/gomod2nix";
  rev = "71c797eb0d83f33de7e0247b3ffe7120d98c6b49";
}}/overlay.nix"
