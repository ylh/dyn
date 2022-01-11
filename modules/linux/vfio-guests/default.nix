{ config, pkgs, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.virtualisation.vfio-guests;
in {
  options.virtualisation.vfio-guests = {
    enable = mkEnableOption ''
      <literal>vfio-guests</literal>; note that supplementary services will not
      be installed if no guests are specified'';
    hostDevs = mkOption {
      description = ''
        Devices from the host made available to <literal>guests</literal>. Note
        that addresses are typically reported by system tools in hex, whereas
        integers in Nix are always decimal.
      '';
      type = attrsOf (submodule ./dev.nix);
    };
    guests = mkOption {
      description = ''
        Guests made available as
        <filename>vfio-guest@‹name›.service</filename>. This is achieved with a
        single generic <filename>vfio-guest@.service</filename>, and a
        <filename>vfio-guest@‹name›.service.d/override.conf</filename> per
        guest, if necessary.
      '';
      type = attrsOf (submoduleWith {
        modules = [ ./guest.nix ];
        specialArgs.parentCfg = cfg;
      });
    };
    guestPkg = mkOption {
      description = ''
        Package containing guest definitions as <filename>‹name›.xml</filename>
        at its root.
      '';
      type = package;
      readOnly = true;
    };
    mkDev = mkOption {
      description = ''
        Function that creates a device entry with defaults and type checks
        in the same manner as <literal>hostDevs</literal> entries. Not actually
        used internally, but provided for convenience when specifying guest
        configs. Example: <literal>mkDev { bus = 3; }</literal>
      '';
      readOnly = true;
      visible = "shallow";
      type = functionTo (submodule ./dev.nix);
    };
  };
  config = mkIf cfg.enable {
    # assert libvirtd.enable, and that each guest's device names look sensible
    assertions = let
      assertEmptyCond = n: v: f: how: let
        badDevs = f v.devNames;
      in {
        assertion = badDevs == [];
        message = ''
          virtualisation.vfio-guests.guests.${n} contains ${how} device(s): ${
            concatStringsSep ", " badDevs
          }'';
      };
      getUnknowns = subtractLists (attrNames cfg.hostDevs);
      getDupes = xs: filter (e: count (e': e' == e) xs > 1) xs;
      assertGuestDevs = n: v: [
        (assertEmptyCond n v getUnknowns "unknown")
        (assertEmptyCond n v getDupes "duplicate")
      ];
    in toList {
      assertion = config.virtualisation.libvirtd.enable;
      message = "vfio-guests cannot function without libvirtd";
    } ++ concatLists (mapAttrsToList assertGuestDevs cfg.guests);

    # if we have any guests specified, install the generic guest service
    systemd.services."vfio-guest@" = let
      v = "${pkgs.libvirt}/bin/virsh";
    in mkIf (cfg.guests != {}) rec {
      path = with pkgs; [ libvirt ];
      serviceConfig = {
        TimeoutStopSec = "3m";
        ExecStart = ''
          ${v} 'create ${cfg.guestPkg}/%I.xml --autodestroy; event %I lifecycle'
        '';
        ExecStop = "${pkgs.writeShellScript "vfio-guest-stop.sh" ''
          while :; do
            case `virsh domstate $1` in
              running) virsh shutdown $1;;
              paused) virsh resume $1;;
              pmsuspended) virsh dompmwakeup $1;;
              "in shutdown");;
              *) break;;
            esac
          sleep 5
          done
        ''} %I";
      };
      after = [ "libvirtd.service" ];
      requires = after;
    };

    # any guest that steals host graphics will express it by depending on this
    systemd.services.unbind-vtcons = let
      bind = pkgs.writeShellScript "unbind-vtcons.sh" ''
        echo $1 > /sys/class/vtconsole/vtcon0/bind
        echo $1 > /sys/class/vtconsole/vtcon1/bind
      '';
    in mkIf (
      any (g: elem "unbind-vtcons.service" g.requires) (attrValues cfg.guests)
    ) {
      unitConfig = {
        StopWhenUnneeded = true;
        RefuseManualStart = true;
        RefuseManualStop = true;
        Conflicts = [ "display-manager.service" ];
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${bind} 0";
        ExecStop = "${bind} 1";
        ExecStopPost = "systemctl start display-manager.service";
      };
    };

    virtualisation.vfio-guests.mkDev = x: (
      evalModules { modules = [ ./dev.nix x ]; }
    ).config;

    # this could be less gruesome if we loosened up about whitespace
    systemd.packages = let
      nonEmpty = s: optionalString (s != [] || s != "");
      mkSpecific = v: let
        header = optionalString (v.requires != [] || v.extraUnitConfig != "") ''
          [Unit]
        '';
        reqs = concatStringsSep " " v.requires;
        requires = nonEmpty v.requires ''
          Requires=${reqs}
          After=${reqs}
        '';
        conflicts = nonEmpty v.conflicts ''
          Conflicts=${concatStringsSep " " v.conflicts}
        '';
        extra = nonEmpty v.extraUnitConfig "${v.extraUnitConfig}\n";
      in concatStrings [ header requires conflicts extra ];
      writeConf = n: let
        specific = mkSpecific cfg.guests.${n};
      in nonEmpty specific ''
        pd=vfio-guest@${n}.service.d
        mkdir $pd
        echo -n ${escapeShellArg specific} > $pd/override.conf
      '';
      confs = filter (x: x != "") (map writeConf (attrNames cfg.guests));
    in mkIf (confs != []) [ (pkgs.runCommand "vfio-guest-overrides" {} ''
      od=$out/etc/systemd/system
      mkdir -p $od
      pushd $od
      ${concatStrings confs}
      popd
    '') ];

    virtualisation.vfio-guests.guestPkg = pkgs.callPackage ./guestPkg.nix {
      guestDefns = mapAttrs (_: v: v.xml) cfg.guests;
    };
  };
}