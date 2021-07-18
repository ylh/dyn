with builtins;
{ pkgs, lib, config, options, ... }: let
  pathElse = f: p: d: if pathExists p then f p else d;
  cfg = {
    contrib = ./contrib;
  } // pathElse import ./cfg.nix {};
  mylib' = import ./mylib;
  mylib = mylib' { inherit lib; };
  
in with cfg; let
  tackOn = p: pathElse (x: import x {
  	lib = mylib;
    inherit pkgs config options; 
  }) (contrib + "/${p}") {};
in {
  imports = mylib.hereFlatPaths ./modules
         ++ pathElse lib.hereFlatPaths (contrib + "/modules") []
         ++ [ (tackOn "dynamic.nix") (tackOn "dynamic") ];
  config = {
    nixpkgs.overlays = [
      (self: super: {
        lib = mylib' { inherit (super) lib; };
      })
      (self: super:
        super.lib.composeManyExtensions (
          super.lib.hereFlatList ./overlays
       ++ pathElse super.lib.hereFlatList (contrib + "/overlays") []) self super
      )
    ];
  };
  options = {
    stong.dynamic = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };
} 
