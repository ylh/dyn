{ config, lib, ... }:

with lib;
with lib.types;

{
  options.me = mkOption {
    type = str;
    description = ''
      Generic global state variable for a username. Meant to prevent repeating
      one's self.
    '';
  };
}
