{ lib, ... }: with builtins; {
  linesMap = lib.concatMapStringsSep "\n";
  wordsMap = lib.concatMapStringsSep " ";
  lines = lib.concatStringsSep "\n";
  lastBy = sep: x: lib.last (lib.splitString sep x);
  overlaysIf = b: os: lib.composeManyExtensions (lib.optionals b os) (_: _: {});
  systemContains = s: elem s (split "-" currentSystem);
}