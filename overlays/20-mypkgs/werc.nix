{ stdenv, lib, plan9port, perl, ed, gawk
, variant ? null, users ? {}, initrc ? ""}:

assert lib.elem variant [ null "perl" ];

stdenv.mkDerivation rec {
  pname = "werc";
  version = "1.5.0";
  src = builtins.fetchTarball {
    url = "http://werc.cat-v.org/download/werc-${version}.tar.gz";
    sha256 = "0ci86y5983ziyjvz8099p3bqryrq5w2z1wg4jmm8gdbbhvgk4fr6";
  };

  buildInputs = [ plan9port ] ++ lib.optional (variant == "perl") perl;
  nativeBuildInputs = [ ed gawk ];

  phases = "unpackPhase configurePhase installPhase fixupPhase";

  configurePhase = let
    echo = arg: "echo ${lib.escapeShellArg arg}";
  in ''
    rm -r ${lib.concatStringsSep " " ([
      "etc/users/GROUP_AND_USER_ACCOUNTS"
      "bin/aux"
      "bin/contrib/{fix-rc-scripts,hgweb*,tcp80,rc-httpd,webserver.rc}"
    ] ++ lib.optional (variant != "perl") "bin/contrib/markdown.pl")}
    ${echo ''
      . ${plan9port}/plan9/bin/9.rc
      plan9port=$PLAN9
      ${initrc}
    ''} > etc/initrc.local
    ${let
      lines = lib.concatStringsSep "\n";
      per_user = username: { members, password }:
        let
          dir = "etc/users/${username}";
          echoInto = n: c: lib.optional (c != null) "${echo c} > ${dir}/${n}";
        in lines ([ "mkdir ${dir}" ]
        ++ echoInto "members" (if members != null then lines members else null)
        ++ echoInto "password" password);
    in lines (lib.mapAttrsToList per_user users)}
  '';

  installPhase = ''
    [ -e $out ] || mkdir -p $out
    cp -r apps bin etc lib pub tpl $out/
  '';

  fixupPhase = ''
    cd $out
    do_ed() { echo "$1"$'\nwq\n' | ed -s $f; }
    fixup9() {
      for f in `grep -l -r '^#!.*/'$1 .`; do
        local p=`sed 1q $f`
        do_ed "/$1/s,[^[:space:]]*,#!${plan9port}/plan9/bin/$1," $f
        local n=`sed 1q $f`
        echo "$f: interpreter directive changed from \"$p\" to \"$n\""
      done
    }
    fixup9 awk
    fixup9 rc
    f=./bin/werc.rc
    p=`sed -n /pwd/p $f`
    do_ed '/`{pwd}/s,pwd,${plan9port}/plan9/bin/pwd,' $f
    n=`sed -n /pwd/p $f`
    echo "$f: call changed from \"$p\" to \"$n\""
    f=./bin/cgilib.rc
    cgilib() {
      p=`awk '/ \/bin\/echo/ {print; exit}' $f`
      do_ed '/ \/bin\/echo/s,/bin/echo,${plan9port}/plan9/bin/echo,' $f
      n=`awk '/plan9\/bin\/echo/ && ++n == '$1' {print; exit}' $f`
      echo "$f: call changed from \"$p\" to \"$n\""
    }
    cgilib 1
    cgilib 2
  '';

  meta = with lib; {
    description = "CGI web framework written in the Plan 9 shell";
    homepage = "http://werc.cat-v.org/";
    license = licenses.publicDomain;
    platforms = plan9port.meta.platforms;
    maintainers = [ maintainers.ylh ];
  };
}
