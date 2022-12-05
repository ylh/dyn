{
  contrib ? ../.,         # secondary search path
  excl ? [],              # files to exclude from search
  defaultExcludes ? true, # you do not want to set this to false
  imports ? [],           # pin home-manager etc here
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
  mylib = mylib' lib;

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

  importIfPath = mylib.applyIf (x: isPath x || isString x) import;
  enhance = mylib.compose enhance' importIfPath;
  paths = mylib.hereFlatPaths ./modules ++
    mylib.hereFlatPaths (mylib.listingExcept contrib excludes);
in {
  imports = map enhance paths ++ imports;
  nixpkgs.overlays = [
    (self: super: { lib = mylib' super.lib; })
    (self: super:
      super.lib.composeManyExtensions (
           super.lib.hereFlatList ./overlays
        ++ pathElse super.lib.hereFlatList (contrib + "/overlays") []
      ) self super
    )
  ];
}; in if others then me else [ me ]
