{ lib, ... }: rec {
  launchdBasic = argv: {
    serviceConfig = {
      ProgramArguments = argv;
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
    };
  };
  sysUser = pkgs: kw:
    let t = "${kw}.target";
    systemctl= "${pkgs.systemd}/bin/systemctl";
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
}