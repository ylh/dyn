self: { mpd, game-music-emu, stdenv, ... }: {
  mpd = mpd.override { inherit stdenv; };
  game-music-emu = game-music-emu.overrideAttrs (old: {
    cmakeFlags = [ "-DENABLE_UBSAN=OFF" ];
  });
}