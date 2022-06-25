# this module is 4 times the size of the entire cgd repository

{ config, pkgs, lib, ... }: with lib; with types; let
  long = "Common Gateway Daemon";
  cfg = config.services.cgd;

  srv' = n: suffix: "<filename>cgd@${
    if n != "" then "<replaceable>${n}</replaceable>" else ""
  }.service${suffix}</filename>";
  srv = srv' "name" "";

  assignmentOf = x: "_CGD${x}";
  varOf = x: "\$${assignmentOf x}";

  attrPath = listOf str // {
    description = "attribute path";
    check = x: isList x;
    merge = mergeEqualOption;
  };

  # the names here enumerate the config options that influence cli args
  cgdArgs = {
    # ABSOLUTELY DISGUSTING - functions in here handle the closing quote
    # while cgdArgOf handles the opening quote, so env can create entries
    env = v': concatStringsSep "\n" ([ "${optionalString (v' != {})
      "-e ${concatStringsSep "," (attrNames v')}"
    }\"" ] ++ mapAttrsToList (n: v: "Environment=\"${n}=${v}\"") v');
    protocol = v: "${if v == "fcgi" then "-f" else ""}\"";
    addr = v: "-a ${v}\"";
    cgi = v: "-c ${v}\"";
    pwd = v: if v == null then "" else "-w ${v}\"";
  };
  cgdArgOf = n: v: "Environment=\"${assignmentOf n}=${cgdArgs.${n} v}";
  cgdArgAt = i: n: cgdArgOf n i.${n};

  catMapLines = f: concatMapStrings (x: let
    app = f x;
  in if app == "" then "" else "\n" + app);

  # shr enumerates config options that have configurable defaults
  shr.env = mkOption {
    type = attrsOf str;
    default = {};
    example = { CGIT_CONFIG = "/foo/bar"; };
    description = ''
      Additional environment variables <literal>cgd</literal> passes through
      to the CGI executable. It always passes <literal>$PATH</literal> and
      <literal>$PLAN9</literal> no matter what. Names starting with
      <literal>${varOf ""}</literal> are reserved for the implementation of
      this module.
    '';
  };
  shr.protocol = mkOption {
    type = enum [ "fcgi" "http" ];
    default = "fcgi";
    description = "Protocol to serve.";
  };
  shr.user = mkOption {
    type = nullOr str;
    default = null;
    description = ''
      User to run under, typically specific to the CGI script in question, so
      none are created here. This or the default must be non-null.
    '';
  };
  shr.rdepPath = mkOption {
    type = either str attrPath;
    default = [ "unitConfig" "Upholds" ];
    example = "wants";
    description = ''
      The attribute within the unit given by <option>rdepOf</option>, to which
      ${srv} is appended. A bare string is equivalent to a one-item list.
    '';
  };
  shr.rdepOf = mkOption {
    type = nullOr (either str attrPath);
    example = [ "targets" "foo" ];
    description = ''
      This module creates one unit, ${srv' "" ""}, which is symlinked to ${srv}
      for each instance <replaceable>name</replaceable>, each given its own
      ${srv' "name" ".d/override.conf"}. This has nice semantics on the systemd
      side (insofar as that's possible), but at the time of writing (Jul 2021),
      the <filename>.wants/</filename> symlink workaround described in
      <xref linkend="opt-systemd.units.services._name_.wantedBy"/> is only 
      applicable to declarative units per <option>systemd.units</options> and
      friends, which, for technical reasons, the ${srv' "name" ".d/"} configs
      are not. </para> <para>
      The solution to staying declarative here is to specify the dependency in
      the dependent unit itself. The given path in <option>systemd</option>,
      or the given bare name in <option>systemd.services</option>, has ${srv}
      appended to the attribute specified in <option>rdepPath</option>. Given
      <literal>null</literal>, the instance is disabled, as it has nothing to
      latch onto.
    '';
  };
  shr.extraUnit = mkOption {
    type = lines;
    default = "";
    description = ''
      Additional lines appended verbatim to ${srv' "name" ".d/override.conf"},
      appended to any set default. Starts in a context of
      <literal>[Service]</literal>.
    '';
  };

  vNames = attrNames cgdArgs;
  iNames = subtractLists (attrNames shr) vNames; # only in instances
  dNames = intersectLists (attrNames shr) vNames; # in instances & base

  # the names specified right here should == iNames
  inst.options = {
    addr = mkOption {
      type = str;
      example = ":3333";
      description = ''
        <link xlink:href="https://golang.org/pkg/net#Dial"/> defines possible
        forms for the listen address. A best effort is made to check for
        exact duplicate values between instances, but this can't catch all
        conflicts.
      '';
    };
    cgi = mkOption {
      type = str;
      description = "CGI executable; can be relative to <option>pwd</option>.";
      example = "";
    };
    pwd = mkOption {
      type = nullOr path;
      default = null;
      description = "Working directory for the CGI executable.";
      example = literalExample "\${pkgs.cgit}/bin/";
    };
  } // mapAttrs (n: v: v // { default = cfg.${n}; }) shr;
in {
  options.services.cgd = {
    instances = mkOption {
      type = attrsOf (submoduleWith { modules = [ inst ]; });
      default = {};
      description = ''
        Instances of the ${long}. If no instances are defined, the
        <literal>cgd</literal> service is disabled.
      '';
    };
    package = mkOption {
      type = package;
      default = pkgs.cgd;
      example = literalExample "pkgs.pkgsStatic.cgd";
      description = "Which package will be used.";
    };
  } // mapAttrs (n: v: v // { description = ''
    Default <option>${n}</option> setting used by instances.
  ''; }) shr;

  config = let
  	enabled' = filterAttrs (_n: { rdepOf, ... }: rdepOf != null) cfg.instances;
    enabled = let
      # best-effort error out on duplicate listen addresses
      uAddrs = lib.unique (mapAttrsToList (_n: { addr, ... }: addr) enabled');
      mkPair = a: nameValuePair
        a (filter (n: cfg.instances.${n}.addr == a) (attrNames cfg.instances));
      dupes = filter ({ name, value }: length value > 1) (map mkPair uAddrs);
    in if dupes != [] then let
      fmt = { name, value }:
        "Duplicate address ${name} in ${
          concatMapStringsSep ", " (n: "services.cgd.instances.${n}") value
        }";
      in throw (concatMapStringsSep "\n" fmt dupes)
    else
    	enabled';

    # ``merge'' the rdeps. surely there is a better way to do this?
    rdeps' = mapAttrsToList (n: { rdepOf, rdepPath, ... }: let
      rdepOf' = if isString rdepOf then [ "services" rdepOf ] else rdepOf;
      rdepPath' = toList rdepPath;
    in {
        path = rdepOf' ++ rdepPath';
        name = [ "cgd@${n}.service" ];
    }) enabled;
    rdeps = foldl' (acc: { path, name }: let
      new = setAttrByPath path (if hasAttrByPath path acc then  
        name ++ attrByPath path (abort "the universe is ending") acc
      else
        name);
    in recursiveUpdate acc new) {} rdeps';

    systemd.units."cgd@.service".text = ''
      [Unit]
      Description=Common Gateway Demon (wrapping %i)

      [Service]
      ExecStart=${cfg.package}/bin/cgd ${
        concatMapStringsSep " " varOf vNames
      }${
        optionalString (cfg.user != null) "\nUser=${cfg.user}"
      }${
        catMapLines (cgdArgAt cfg) dNames
        # sadly, no real way to get restart triggers for individual
        # override.confs. this is due to how switch-to-configuration.pl deals
        # with overrides (it doesn't). the best we get is the ability to
        # restart all instances if any of them changes by shoving them all in
        # the template's closure. i honestly can't fault nixos for refusing to
        # dignify all of systemd's abstractions, and i'm increasingly wondering
        # why i bothered doing so with this instance nonsense
      }
      X-Restart-Triggers=${builtins.toString systemd.packages}
      X-RestartIfChanged=true
    '';

    systemd.packages = let
      mkPkg = instance: let
        dir = "cgd@${instance}.service.d";
        i = cfg.instances.${instance};
      in pkgs.runCommand "cgd-instance-${instance}" {} ''
        od=$out/etc/systemd/system/${dir}
        mkdir -p $od
        echo -n ${escapeShellArg ''
          [Service]
          ${
            optionalString
              (if i.user == null && cfg.user == null then
                abort ("In services.cgd.instances.${instance}: "
                     + "default and specific user cannot both be null")
              else
                i.user != cfg.user)
            "User=${i.user}"
          }${
            catMapLines
              (n: optionalString (i.${n} != cfg.${n}) "${cgdArgAt i n}")
              dNames
          }${
            catMapLines (cgdArgAt i) iNames
          }${
            let
              eu = cfg.extraUnit + i.extraUnit;
            in optionalString (eu != "") ("\n" + eu)
          }
        ''} > $od/override.conf
      '';
    in map mkPkg (attrNames enabled);
  in {
    systemd = optionalAttrs (enabled != {}) (recursiveUpdate rdeps systemd);
  };
}
