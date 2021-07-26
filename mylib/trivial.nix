{ lib, ... }: rec {
  applyIf = g: f: a: applyIf' (g a) f a;
  applyIf' = b: f: a: if b then f a else a;
  compose = f: g: x: f (g x);
  compose' = lib.flip (lib.foldr lib." ");
}
