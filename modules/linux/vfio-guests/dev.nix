{ config, pkgs, lib, ... }:
with lib;
with lib.types;
{
  options = let
    addrDesc = x: "${x} of the device's host PCIe address.";
  in {
    domain = mkOption {
      description = addrDesc "Domain";
      type = ints.u16;
      default = 0;
    };
    bus = mkOption {
      description = addrDesc "Bus";
      type = ints.u8;
      default = 0;
    };
    slot = mkOption {
      description = addrDesc "Slot";
      type = ints.u8;
      default = 0;
    };
    function = mkOption {
      description = addrDesc "Function or functions";
      type = let nibble = ints.between 0 15; in either nibble (listOf nibble);
      default = 0;
    };
    rom = mkOption {
      description = "Option ROM associated with the device.";
      type = nullOr (either str path);
      default = null;
    };
    isHostGraphics = mkOption {
      description = ''
        Whether the device is required for the host to output graphics. When
        true, guests using the device will depend on a so-called
        <filename>unbind-vtcons.service</filename> whose purpose is, obviously,
        to unbind virtual consoles, as well as introduce a conflict with the
        display manager. By default, this is set up with the assumption that
        the EFI framebuffer is disabled in kernel arguments. This may be
        unsuitable for Nvidia users, or users who start X without a display
        manager, who are encouraged to inspect
        <literal>config.systemd.services.unbind-vtcons</literal>
        and modify it to suit their systems.
      '';
      type = bool;
      default = false;
    };
  };
}
