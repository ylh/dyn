{ lib, stdenv, fetchgit, ed, mksh, plan9port }:
assert stdenv.hostPlatform.isStatic;
let
  pwd = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/0intro/plan9/main/sys/src/cmd/pwd.c";
    sha256 = "15ixlnkl8v642skz2qjn3djxcg91f5gjc0dppmsdzjhgcxgn0gph";
  };
in stdenv.mkDerivation rec {
  pname = "_9base";
  version = "2019-09-11";
  src = fetchgit {
    url = "git://git.suckless.org/9base";
    rev = "63916da7bd6d73d9a405ce83fc4ca34845667cce";
    sha256 = "04j8js4s3jmlzi3m46q81bq76rn41an58ffhkbj9p5wwr5hvplh8";
  };

  nativeBuildInputs = [ ed ];

  postPatch = let
    ed = f: s: ''
      ed -s ${f} <<EOF
      ${s}wq
      EOF
    '';
  in ''
    ${ed "config.mk" ''
      /^PREFIX/s,/usr/local,$out,
      /386/s/^/#/
      /x86_64/s/^#//
      /^LDFLAGS/d
      /^AR/s/ar/$AR/
      /^CC/d
    ''}
    ${ed "lib9/u.h" ''
      /_BSD_SOURCE/d
      /_SVID/s//_DEFAULT/
    ''}
    ${ed "std.mk" ''
      /strip/s//''${STRIP}/
    ''}
    ${ed "sam/Makefile" ''
      /strip/s//''${STRIP}/
    ''}
    
    mkdir pwd
    cat <${pwd} >pwd/pwd.c
    ${ed "pwd/pwd.c" ''
      /USED/d
    ''}
    cp pbd/pbd.1 pwd/pwd.1
    cp pbd/Makefile pwd/Makefile
    ${ed "pwd/Makefile" ''
      g/pbd/s//pwd/g
    ''}
    ${ed "Makefile" ''
      /pbd/y
      ??x
      s//pwd/
    ''}
  '';
  
  dontConfigure = true;
  dontPatchShebangs = true;

  postFixup = ''
    for i in bin/9{,.rc}; do
      substitute ${plan9port.src}/$i $out/plan9/$i --replace /usr/local $out
      chmod +x $out/plan9/$i
    done
    mkdir -p $out/bin
    substituteInPlace $out/plan9/bin/9 --replace /bin/sh ${mksh}/bin/mksh
    cp $out/{plan9/,}bin/9
  '';
  
  meta = with lib; {
    description = "revived minimalist port of Plan 9 userland to Unix";
    homepage = "https://tools.suckless.org/9base/";
    # TODO: tell upstream that plan 9 has been relicensed to mit
    license = with licenses; [ mit lpl-102 ]; 
    platforms = platforms.linux;
    maintainers = [ maintainers.ylh ];
  };
}
