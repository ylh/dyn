# auxiliary service for the vanilla nixos fail2ban config; reads sshd logs for
# successful login attempts and shoves corresponding IPs in a tmpfile whose
# lifespan is that of the service. lets you test weird ssh configurations
# without locking yourself out

{ config, pkgs, lib, ... }: with lib; with lib.types; let
  n = "ignorecached"; # kind of hate this name so let's make it easy to change
  long = "fail2ban Ignore Cache Daemon";
  cfg = config.services.${n};
in {
  options.services.${n} = {
    enable = mkEnableOption "the ${long}";
    cacheFile = mkOption {
      type = path;
      default = "/tmp/ignorecache";
      description = "Where to put the cache file. And where to find it.";
    };
    user = mkOption {
      type = str;
      default = n;
      description = ''
        User to run under. Must have the ability to read the systemd journal.
        If left at the default, such a user will be created, but if you already
        have one lying around, no sense in yet another.
      '';
    };
    appendToJail = mkOption {
      type = bool;
      default = true;
      description = ''
        Whether to append to the default fail2ban jail config. If you have a
        particularly exotic configuration, you might need to disable this.
      '';
    };
    checkCommand = mkOption {
      type = functionTo str;
      default = let cf = cfg.cacheFile; in
        ip: "[ -e ${cf} ] && ${pkgs.gnugrep}/bin/grep -qF ${ip} ${cf}";
      defaultText = "${''
        let cf = cfg.cacheFile; in
        ip: [ -e ''${cf} && ''${pkgs.gnugrep}/bin/grep -qF ''${ip} ''${cf}
      ''}";
      readOnly = true;
      description = ''
        The shell command to consult the cache for an IP, as a function of
        its placeholder in the given context. Used in the default
        <literal>appendToJail</literal> behaviour as well as the daemon itself.
      '';
    };
  };
  config = mkIf cfg.enable {
    systemd.services.ignorecached = {
      description = long;
      partOf = [ "fail2ban.service" ];
      wants = [ "sshd.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.writeShellScript n ''
          PATH=$PATH:${pkgs.gnused}/bin
          e='s/.*Accepted [^ ]* for [^ ]* from ([^ ]*) .*/\1/p';
          journalctl -fu sshd | sed -unE "$e" | while read; do
            { ${cfg.checkCommand "\"$REPLY\""}; } ||
              echo "$REPLY" >> ${cfg.cacheFile}
          done
          ''}";
        ExecStop = "${pkgs.util-linux}/bin/kill -TERM $MAINPID";
        User = cfg.user;
      };
    };
    users.users = optionalAttrs (cfg.user == n) {
      ${n} = {
        group = "adm";
        isSystemUser = true;
        description = long;
      };
    };
    services.fail2ban.jails.DEFAULT = optionalString cfg.appendToJail ''  
      ignorecommand = ${cfg.checkCommand "'<ip>'"}
    '';
  };
}
