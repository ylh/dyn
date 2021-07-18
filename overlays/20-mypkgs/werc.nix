{ stdenv, lib, variant ? null, plan9port, ed, etcpop ? { }, perl }:

assert lib.elem variant [ null "perl" ];

let
  inherit (lib) concatStringsSep escapeShellArg mapAttrsToList optional;
  lines = concatStringsSep "\n";
  
  removals = concatStringsSep " " ([
    "etc/users/GROUP_AND_USER_ACCOUNTS"
    "bin/aux"
    "bin/contrib/{fix-rc-scripts,hgweb*,tcp80,rc-httpd,webserver.rc}"
  ] ++ optional (variant != "perl") "bin/contrib/markdown.pl");

  initrc = ''
    plan9port=${plan9port}/plan9
  '' + etcpop.initrc or "";

  users = lines (mapAttrsToList (username: { members, password }: let
    d = "etc/users/${username}";
    m = if members != null then lines members else null;
    e = n: c: optional (c != null) "echo ${escapeShellArg c} > ${d}/${n}";
  in lines ([ "mkdir ${d}" ] ++ e "members" m ++ e "password" password))
           etcpop.users or {});

in stdenv.mkDerivation rec {
  pname = "werc";
  version = "1.5.0";

  src = builtins.fetchTarball {
    url = "http://werc.cat-v.org/download/werc-${version}.tar.gz";
    sha256 = "0ci86y5983ziyjvz8099p3bqryrq5w2z1wg4jmm8gdbbhvgk4fr6";
  };
  buildInputs = [ plan9port ed ] ++ optional (variant == "perl") perl;

  phases = "unpackPhase configurePhase installPhase fixupPhase";
  configurePhase = ''
    rm -r ${removals}
    echo ${escapeShellArg initrc} > etc/initrc.local
    ${users}
  '';
  installPhase = ''
    [ -e $out ] || mkdir -p $out
    cp -r apps bin etc lib pub tpl $out/
  '';
  fixupPhase = ''
    do_ed() { echo "$1"$'\nwq\n' | ed -s $f; }
    fixup9() {
      for f in `grep -l -r '^#!.*/'$1 .`; do
        local p=`sed 1q $f`
        do_ed "/$1/s,[^[:space:]]*,#!${plan9port}/bin/$1," $f
        local n=`sed 1q $f`
        echo "$f: interpreter directive changed from \"$p\" to \"$n\""
      done
    }
    fixup9 awk
    fixup9 rc
    f=./bin/werc.rc
    p=`sed -n /pwd/p $f`
    do_ed '/`{pwd}/s,pwd,${plan9port}/bin/pwd,' $f
    n=`sed -n /pwd/p $f`
    echo "$f: call changed from \"$p\" to \"$n\""
  '';
}
