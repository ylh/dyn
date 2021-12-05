{ lib, ... }: {
  assertVersion = expected: { version, pname, ... }:
    lib.assertMsg
      (builtins.compareVersions version expected != 1)
      ("This overlay was written for ${pname} ${expected}. " +
       "Ensure that it is still necessary for ${version}.");
}
