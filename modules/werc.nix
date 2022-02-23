# This module shoehorns werc, the sane web anti-framework, into NixOS. Usually,
# werc is run, configured, and populated with content, from a single directory
# tree. Provided is nearly the bare minimum required to:
# - configure users and so on without pointing outside the Nix store, and
# - determine whether we can dispense with Perl.
# Yet, somehow, this module is longer than werc.rc itself. There's a lesson in
# that.

{ config, lib, pkgs, ... }:

with lib;
with lib.types;

let
  cfg = config.programs.werc;
  stong = lib;

  userOpts = { config, lib, pkgs, ... }: {
    options.members = mkOption {
      type = nullOr (listOf str);
      default = null;
      example = [ "benry" "gordon" "bubby" "tommy" ];
      description = ''
        Names of users in the respective group. <literal>null</literal> is 
        distinct from an empty list; the latter still produces a
        <filename>members</filename> file, just empty.
      '';
    };
    options.password = mkOption {
      type = nullOr str;
      default = null;
      example = "hunter2";
      description = ''
        Plaintext password. Yes, this winds up in the Nix store. Yes, anyone
        with a shell on your machine could deface your blog.
      '';
    };
  };
in {
  imports = [
    (mkAliasOptionModule
      [ "programs" "werc" "groups" ]
      [ "programs" "werc" "users" ]
    )
  ];

  options.programs.werc = {
    enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Whether to configure werc.
      '';
    };
    users = mkOption {
      type = attrsOf (submodule userOpts);
      default = { };
      description = ''
        Users and groups in werc share the same namespace. An entry is a group
        when it has members, and is a user when it has a password; it can
        easily have both. The alias <literal>groups</literal> is offered for
        organisation.
      '';
    };
    fltrCache = mkOption {
      type = bool;
      default = true;
      description = ''
        Whether or not to wrap <literal>formatter</literal> in a call to
        <command>fltr_cache</command>, werc's caching layer.
      '';
    };
    formatter = mkOption {
      type = oneOf [ (enum [ "markdown.pl" "md2html.awk" ]) string ];
      default = "md2html.awk";
      description = ''
        Included in werc are <filename>markdown.pl</filename>, the original
        perl markdown implementation from daringfireball, which will add perl
        to werc's runtime dependencies, and <filename>md2html.awk</filename>,
        which is compatible with both plan9port and GNU/BSD/etc awk.
        Alternatively, set the name to any formatter in
        <literal>extraPath</literal>. It must be the basename of the
        executable, as <literal>fltr_cache</literal> will use it to name the
        cache directory.
      '';
    };
    extraPath = mkOption {
      type = listOf package;
      default = [];
      description = ''
        Store paths whose <filename>/bin</filename> will be added to werc's
        path.
      '';
    };
    extraConfig = mkOption {
      type = lines;
      default = "";
      example = ''
        debug=false
        enabled_apps=(bridge wman paste)
      '';
      description = ''
        Extra lines appended to <filename>initrc.local</filename>.
      '';
    };
    sitesDir = mkOption {
      type = path;
      example = "/var/www";
      description = ''
        Usually <literal>sites</literal> in the werc installation directory,
        but this is probably a bad idea in Nix. For a request with
        <literal>Host: example.com</literal>, attempt to serve from
        <literal>sitesDir/example.com</literal>. There is no default; this
        must be specified.
      '';
    };
    package = mkOption {
      type = package;
      default = pkgs.werc;
      defaultText = "pkgs.werc";
      example = literalExpression ''
        pkgs.werc.override {
          plan9port = pkgs.plan9port-static;
        }
      '';
      description = ''
        The werc derivation to be added to the system environment. It will be
        called with <literal>.override</literal> to populate
        <filename>etc</filename> in the werc installation directory according
        to the configuration.
      '';
    };
    wrappedPackage = mkOption {
      type = package;
      readOnly = true;
      description = ''
        The werc derivation specified in <literal>package</literal>, wrapped
        with this module's configuration options. This option is to provide
        the effective derivation for whatever ends up calling werc as a CGI
        script, though more creative uses are imaginable.
      '';
    };
  };

  config = mkIf cfg.enable (let
    etcpop' = {
      inherit (cfg) users;
      initrc = lib.concatStringsSep "\n" [
        "sitesdir=${cfg.sitesDir}"
        "path=(${lib.concatStringsSep " " ([
          # this is appended to a snippet in the package that sets
          # $plan9port and $coreutils
          "$plan9port/bin" "." "./bin" "./bin/contrib" "$coreutils/bin"
        ] ++ builtins.map (p: "${p}/bin") cfg.extraPath)})"
        "formatter=${
          if cfg.fltrCache then
            "(fltr_cache ${cfg.formatter})"
          else
            cfg.formatter
        }"
        cfg.extraConfig
      ];
    };
  in {
    programs.werc.wrappedPackage = cfg.package.override {
      etcpop = etcpop';
      variant = if cfg.formatter == "markdown.pl" then perl else null;
    };
    environment.systemPackages = [ cfg.wrappedPackage ];
  });
}
