{ callPackage, lua, fetchFromGitHub }: let
  mpvbranch = fetchFromGitHub {
    owner = "azuwis";
    repo = "nixpkgs";
    rev = "64bce1df1712a8731a810e1adf7281bce22038e8";
    sha256 = "tKza4OQj0xdSBAUAyP60YqqQnizTqfJT9vClfNKpJbM=";
  };
in callPackage (builtins.import "${mpvbranch}/pkgs/applications/video/mpv") {
  inherit lua;
}
