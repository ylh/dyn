_self: { path, ... }: let
  pkgsIntel = import path { localSystem = "x86_64-darwin"; };
in {
  inherit (pkgsIntel) irssi;
  inherit pkgsIntel;  
}
