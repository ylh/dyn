{ lib, ... }: rec {
  launchdDaemon = argv: {
    serviceConfig = {
      ProgramArguments = argv;
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
  launchdForeground = argv:
    lib.recursiveUpdate
      (launchdDaemon argv)
      ({ serviceConfig.ProcessType = "Background"; });

  sysUser = pkgs: kw:
    let t = "${kw}.target";
    systemctl = "${pkgs.systemd}/bin/systemctl";
    echo = "${pkgs.coreutils}/bin/echo";
    sleep = "${pkgs.coreutils}/bin/sleep";
  in {
    targets.${kw}.Unit = {
      Description = "(User) ${t}";
    };
    services."watch_${kw}" = {
      Service.ExecStart = "${(pkgs.writeShellScript "watch_${kw}" ''
        trap "exit" SIGTERM SIGHUP SIGINT
        d() { ${systemctl} -q is-active ${t} && ${echo} start || ${echo} stop; }
        run() { systemctl --user --no-block $1 ${t}; }
        act=$(d)
        perform $action
        while :; do
          tmp=$(d)
          [ "X$tmp" = "X$act" ] && ${sleep} 60 || { action=$tmp; run $act; }
        done
      '').outPath}";
      Service.Restart = "on-failure";
      Install.WantedBy = [ "default.target" ];
    };
  };

  literalText = attrs: let
    eq = k: v: "${k}=${v}";
    join = name: value: if builtins.isList value then
      lib.concatMapStringsSep "\n" (value': eq name value') value
    else
      eq name value;
  in lib.concatStringsSep "\n" (lib.mapAttrsToList join attrs);

  noManual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  passwd = {
    name ? "", pass ? "", uid ? "", gid ? "",
    desc ? "", home ? "", shell ? "", extra ? ""
  }: let
    u = builtins.toString uid;
    g = builtins.toString gid;
    l = [ name pass u g desc home shell ] ++ lib.optional (extra != "") extra;
  in lib.concatStringsSep ":" l + "\n";

  passwds = lib.concatMapStrings passwd;
}
