_self: super@{ lib, plan9port, ... }: {
  launchd9 = argv: lib.launchdForeground ([ "${plan9port}/bin/9" ] ++ argv);
}
