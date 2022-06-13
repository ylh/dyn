{ lib, ... }: {
  mergeMany = lib.foldl' lib.recursiveUpdate {};
}
