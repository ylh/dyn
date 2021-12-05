{ config, lib, ... }:

with lib;
with lib.types;

{
  options.me = mkOption {
    type = str;
    description = ''
      Who am I?
    '';
  };
}
