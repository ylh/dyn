# ok yes this is awful but so is network_cmds explicitly pulling openssl 1.0.2
_self: { callPackage, ... }: {
  nettools = callPackage ({ lib, runCommand, ... }: let
    cmds = [
      /usr/sbin/arp
      /sbin/ifconfig
      /usr/sbin/ndp
      /usr/sbin/netstat
      /sbin/ping
      /sbin/ping6
      /usr/sbin/rarpd
      /sbin/route
      /usr/sbin/rtadvd
      /usr/sbin/spray
      /usr/sbin/traceroute
      /usr/sbin/traceroute6
    ];
  in runCommand "nettools-impure" {} ''
    B=$out/bin
    mkdir -p $B
    ${lib.concatStringsSep "\n" (builtins.map (p: ''
      cp ${p} $B/${lib.last (lib.splitString "-" p)}
    '') cmds)}
  '') {};
}
