# this could be simplified into runCommands and put back into default.nix
{ stdenv, lib, libvirt, guestDefns, ... }:
with lib;
stdenv.mkDerivation {
  name = "vfio-guests";
  checkInputs = [ libvirt ];
  phases = [ "checkPhase" "installPhase" ];

  checkPhase = concatMapStrings (v: ''
    echo -n ${escapeShellArg v} | virt-xml-validate /dev/stdin domain
  '') (attrValues guestDefns);

  installPhase = ''
    mkdir $out
    ${concatStrings (mapAttrsToList (n: v: ''
      echo -n ${lib.escapeShellArg v} > $out/${n}.xml
    '') guestDefns)}
  '';
}