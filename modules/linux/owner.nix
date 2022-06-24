{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.dyn;
in {
  options.dyn = {
    location = mkOption {
      type = path;
      default = builtins.toString ../..;
      readOnly = true;
      description = ''
        Path to dyn, for access from other modules.
      '';
    };
    owner = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        Username (strictly, key into <literal>users.users</literal>) that will take
        ownership of dyn on system activation.
      '';
    };
    extraDeps = mkOption {
      type = listOf string;
      default = [];
      description = ''
        Additional activation scripts to run before taking ownership.
      '';
    };
  };
  config = mkIf (cfg.owner != null) {
    system.activationScripts.dyn-take-ownership = let
      u = config.users.users.${cfg.owner};
    in {
      deps = [ "users" "groups" ] ++ cfg.extraDeps;
      text = ''
        chown -R ${u.name}:${u.group} ${cfg.location}
      '';
    };
  };
}

