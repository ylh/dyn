self: super: let
  frameworks = super.darwin.apple_sdk.frameworks;
  special = {
    osxutils.args = {
      inherit (frameworks) Carbon Cocoa;
    };
    daemondo.args = {
      inherit (frameworks) CoreFoundation SystemConfiguration IOKit;
      inherit (self.netbsd) mtree;
    };
    afro.caller = super.python3Packages;
  };
  call = (n: v:
    (special.${n}.caller or super).callPackage
    v
    (special.${n}.args or {}));
in super.lib.hereFlatAttrsMap call ./.
