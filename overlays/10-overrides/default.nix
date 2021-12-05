# in here, we patch packages implicitly by name
self: super@{ lib, ...}: lib.hereFlatAttrsMap (n: f: f self super) ./.
