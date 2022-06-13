{ config, pkgs, lib, name, parentCfg, ... }:
with lib;
with lib.types;
let
  l = x: ''<xref linkend="opt-${x}"/>'';
in {
  options = {
    devNames = mkOption {
      description = ''
        Names of devices from ${l "virtualisation.vfio-guests.hostDevs"},
        in the order they will appear in
        ${l "virtualisation.vfio-guests.guests._name_.hostDevs"}.
      '';
      type = listOf str;
      default = [];
    };
    xml = mkOption {
      description = "String containing a libvirt XML domain.";
      type = str;
    };
    hostDevs = mkOption {
      description = ''
        A list of devices from ${l "virtualisation.vfio-guests.hostDevs"},
        in the order they were given in
        ${l "virtualisation.vfio-guests.guests._name_.devNames"},
        intended to be read when building the value passed to
        ${l "virtualisation.vfio-guests.guests._name_.xml"}.
      '';
      readOnly = true;
      visible = "shallow";
      type = listOf (submodule ./dev.nix);
    };
    conflicts = mkOption {
      description = ''
        Names of other services with which this guest directly conflicts. By
        default, full <filename>vfio-guest@‹name›.service</filename> names
        of any other ${l "virtualisation.vfio-guests.guests"} with overlapping
        <literal>devNames</literal>, but others can be added.
      '';
      type = listOf str;
    };
    requires = mkOption {
      description = ''
        Units to depend on. By default, just
        <filename>unbind-vtcons.service</filename> when applicable (see
        ${l "virtualisation.vfio-guests.hostDevs._name_.isHostGraphics"}),
        but more can be added.
      '';
      type = listOf str;
    };
    extraUnitConfig = mkOption {
      description = ''
        Literal text appended to the guest's <literal>override.conf</literal>,
        starting in a <literal>[Unit]</literal> section.
      '';
      default = "";
      type = lines;
    };
  };
  config = {
    hostDevs = map (x: parentCfg.hostDevs.${x}) config.devNames;
    conflicts = attrValues (filterAttrs (name': value:
      name != name' && !mutuallyExclusive value.devNames config.devNames
    ) parentCfg.guests);
    # todo: check if we can read our own hostDevs directly without infrec
    requires = lib.optional
      (any (dn: parentCfg.hostDevs.${dn}.isHostGraphics) config.devNames)
      "unbind-vtcons.service";
  };
}
