self: super@{ lib, ghc, haskellPackages, ... }: {
  ghc = if lib.assertVersion "8.10.7" ghc then
    ghc.overrideAttrs ({ preConfigure ? "", ... }: {
      preConfigure = ''
        pushd libraries
          tar xzf "${haskellPackages.terminfo_0_4_1_5.src}"
          mv terminfo/{config.sub,GNUmakefile,ghc.mk,stack.yaml,README.md} \
            terminfo-*/
          rm -rf terminfo
          mv terminfo-* terminfo
        popd
        ${preConfigure}
      '';
    })
  else
    ghc;
}

