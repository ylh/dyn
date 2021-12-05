self: { plan9port, ... }: plan9port.overrideAttrs ({ patches ? [], ... }: {
  patches = patches ++ [
    ./acme-backport-9front-spacesindent.patch
    ./pwd-import-from-4e.patch
    ./fontsrv-slightly-fudge-height-numbers.patch
    ./fontsrv-leave-vanity-behind.patch
  ];
})
