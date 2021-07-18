self: super: (super.nixpkgs-fmt.overrideAttrs ({...}: rec {
  patches = [ ./permissive-lists.patch ];
  doCheck = false;
}))
