{ config, lib, ... }:

with lib;
with lib.types;
let
  textOf = mapAttrs (_name: value: { text = value; });
in {
  options.home = mkOption {
    type = attrsOf anything;
    default = {};
    description = ''
      Attributes passed through directly to home-manager.
    '';
  };
  options.homedir = mkOption {
    type = attrsOf str;
    default = {};
    description = ''
      Content of files linked into the home directory via home-manager.
    '';
  };
  options.xdg = mkOption {
    type = attrsOf str;
    default = {};
    description = ''
      Content of files linked into the XDG config directory via home-manager.
    '';
  };
  options.home-aliases.enable = mkOption {
    type = bool;
    default = false;
    description = ''
      Turn on top-level aliases for home-manager
    '';
  };
  
  config.home-manager.users.${config.me} = mkIf config.home-aliases.enable (
    mkMerge [
      ({ ... }: { manual = lib.noManual; programs.man.enable = false; })
      { xdg.configFile = textOf config.xdg; }
      { home.file = textOf config.homedir; }
      config.home
    ]
  );
}