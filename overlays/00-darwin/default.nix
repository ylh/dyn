_self: super@{ lib, stdenv, ... }:
  lib.util.overlaysIf stdenv.isDarwin (lib.hereFlatList ./.) super