{
  contrib ? ../.,         # secondary search path
  excl ? [],              # files to exclude from search
  defaultExcludes ? true, # you do not want to set this to false
  imports ? [],           # pin home-manager etc here
  unstable ? null,        # need unstable? pin its derivation here
  enhancePins ? false,    # add mylib to imports. generally unnecessary
  others ? false,         # do not present as a singleton list
  contagious ? false,     # provide dyn(.enhance) as a module argument
  ...
}:
with builtins;
let me = { lib, pkgs, ... }: let
  excludes = excl ++ lib.optionals defaultExcludes [
    "configuration.nix" "darwin-configuration.nix" "home.nix" "overlays"
  ] ++ lib.optional (contrib == ../.) "dyn";
  pathElse = f: p: d: if pathExists p then f p else d;
  mylib' = import ./mylib;
  mylib = mylib' { inherit lib; };

  enhanceBy = name: value: mylib.applyIf lib.isFunction (m': let
    initArgs = lib.functionArgs m';
  in mylib.applyIf' (initArgs ? "${name}") (m:
    lib.setFunctionArgs (args: m (args // { "${name}" = value; })) (initArgs)
  ) m');
  enhance' = mylib.compose
    (mylib.applyIf' contagious (enhanceBy "dyn" {
      imports = p: map enhance (mylib.hereFlatPaths p);
      inherit enhance;
    }))
    (enhanceBy "lib" mylib);

  isP = x: isPath x || isString x;
  enhance = mylib.compose enhance' (mylib.applyIf isP import);
  paths = mylib.hereFlatPaths ./modules ++
    mylib.hereFlatPaths (mylib.listingExcept contrib excludes);
in {
  imports = map enhance paths ++ (if enhancePins then
    map enhance imports
  else
    imports);
  nixpkgs.overlays = [
    (self: super: {
      unstablePath = if unstable == null then
        super.path
      else "${unstable}";
    })
    (self: super: {
      lib = mylib' { inherit (super) lib; };
    })
    (self: super:
      super.lib.composeManyExtensions (
        super.lib.hereFlatList ./overlays
     ++ pathElse super.lib.hereFlatList (contrib + "/overlays") []) self super
    )
  ];
}; in if others then me else [ me ]
