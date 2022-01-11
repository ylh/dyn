{ lib, ... }: with builtins; {
  linesMap = lib.concatMapStringsSep "\n";
  wordsMap = lib.concatMapStringsSep " ";
  lines = lib.concatStringsSep "\n";
  lastBy = sep: x: lib.last (lib.splitString sep x);
  overlaysIf = b: os: lib.composeManyExtensions (lib.optionals b os) (_: _: {});
  systemContains = s: elem s (split "-" currentSystem);
  optionalOf = x: with lib; if isList x then
    optionals
  else if isAttrs x then
    optionalAttrs
  else if isString x then
    optionalString
  else throw ("don't know optional of type " + typeOf x);
  optionalBy = b: x: (optionalOf x) b x;
}
