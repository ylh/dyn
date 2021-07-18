with builtins;
{ lib ? (import <nixpkgs> {}).lib, ... }: let
  extFn = n: v: _self: super: let a = v { lib = super; }; in {
    ${n} = super.${n} or {} // a;
  } // a;
in (lib.makeExtensible (self: lib)).extend (lib.composeManyExtensions [
  (extFn "attrsets" ({lib, ...}: {
    # :: (n -> v-> result) -> Attrs -> [result]
    # the name passed to the function is the final name in the attr path
    flattenToList = f: attrs: let
      recurse =
        lib.mapAttrsToList (n: v: if isAttrs v then recurse v else f n v);
    in lib.flatten (recurse attrs);
  }))
  (extFn "nixFiles" ({lib, ...}: let
    # idempotent transforms to cache the result of readDir without making here'
    # too baroque. reusing "default.nix" might seem cheeky, but it's the one
    # name we can actually guarantee is never in contention
    listingOf = d: if isPath d then { "default.nix" = d; } // readDir d else d;
    pathOf = d: if isPath d then d else d."default.nix";

    # we return paths here instead of permitting any direct mapping as that
    # introduces some weird strictness, presumably originating in list length?
    here' = d: lib.filterAttrs (_n: v: v != null) (lib.mapAttrs' (n: v:
      let newPath = pathOf d + "/${n}"; in
      if v == "directory" then
        let newListing = listingOf newPath; in
        lib.nameValuePair n (if isString newListing."default.nix" then
          newPath
        else
          (x: if x == {} then null else x) (here' newListing))
      else if v == "regular" && lib.hasSuffix ".nix" n then
        lib.nameValuePair (lib.removeSuffix ".nix" n) newPath
      else
        lib.nameValuePair n null) (listingOf d));
  in rec {
    # fundamental structure: traverses a directory tree, searching for nix
    # files or directories containing default.nix, producing an attr tree
    # with import paths as leaves
    herePaths = d: here' (readDir d // { "default.nix" = d; });
    
    # like herePaths, but the paths are imported
    here = hereMap lib.id;
    # like `here`, but map f over imported expressions
    hereMap = f: d: lib.mapAttrsRecursive (_n: p: f (import p)) (herePaths d);
    
    # just a list of import paths, such as for module imports lists
    hereFlatPaths = d: lib.flattenToList (_n: v: v) (herePaths d);
    # just the imports in a flat list, e.g. for defining overlay order by
    # grouping them in directories.
    hereFlatList = hereFlatMap (_n: v: v);
    # like hereFlatList, but mapped with f :: (n: v: result)
    hereFlatMap = f: d: lib.flattenToList f (here d);
    
    # like hereFlatList, except a 1-deep attribute set 
    hereFlatAttrs = d: listToAttrs (hereFlatMap lib.nameValuePair d);
    # like hereFlatAttrs, but mapped with f :: (n: v: result)
    hereFlatAttrsMap = f: d: listToAttrs (hereFlatMap
      (n: v: lib.nameValuePair n (f n v)) d);
  }))
  (self: super: (super.composeManyExtensions
    (super.hereFlatMap extFn ./.))
    self super
  )
])
