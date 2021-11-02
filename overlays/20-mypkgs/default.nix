self: super: let
  frameworks = super.darwin.apple_sdk.frameworks;
  special = {
    osxutils = {
      inherit (frameworks) Carbon Cocoa;
    };
    daemondo = {
      inherit (frameworks) CoreFoundation SystemConfiguration IOKit;
    };
  };
  call = (n: v: super.callPackage v (special.${n} or {}));
in super.lib.hereFlatAttrsMap call ./.
