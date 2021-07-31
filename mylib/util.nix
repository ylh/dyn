{ lib, ... }: {
  linesMap = lib.concatMapStringsSep "\n";
  wordsMap = lib.concatMapStringsSep " ";
  lines = lib.concatStringsSep "\n";
}