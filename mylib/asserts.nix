{ lib, ... }: {
  assertVersion = { version, pname, ... }: expected:
    lib.assertMsg
      (builtins.compareVersions version expected != 1)
      ("This overlay was written for ${pname} ${expected}. " +
       "Ensure that it is still necessary for ${version}.");
}
