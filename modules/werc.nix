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

  userOpts = { config, lib, pkgs, ... }: {
    options.members = mkOption {
      type = nullOr (listOf str);
      default = null;
      example = [ "benry" "gordon" "bubby" "tommy" ];
      description = ''
        Names of users in the respective group. <literal>null</literal>
        is distinct from an empty list; the latter still produces a
        <filename>members</filename> file, just empty.
      '';
    };
    options.password = mkOption {
      type = nullOr str;
      default = null;
      example = "hunter2";
      description = ''
        Plaintext password. Yes, this winds up in the
        Nix store. Yes, anyone with a shell on your machine
        could deface your blog.
      '';
    };
  };
in {
  imports = [
    (mkAliasOptionModule [ "programs" "werc" "groups" ] [
      "programs"
      "werc"
      "users"
    ])
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
        Users and groups in werc share the same namespace.
        An entry is a group when it has members, and is
        a user when it has a password; it can easily have
        both. The alias <literal>groups</literal> is offered
        for organisation.
      '';
    };
    fltrCache = mkOption {
      type = bool;
      default = true;
      description = ''
        Whether or not to wrap <literal>formatter</literal>
        in a call to <command>fltr_cache</command>, werc's
        caching layer. Highly suggested to leave this on,
        but it may be useful to turn it off for debugging
        or profiling.
      '';
    };
    formatter = mkOption {
      type = enum [ "markdown.pl" "md2html.awk" ];
      default = "md2html.awk";
      description = ''
        Currently one of two choices for which implementation
        renders markdown pages. Note that choosing
        <command>markdown.pl</command> will draw in Perl as
        a runtime dependency.
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
        Usually <literal>sites</literal> in the werc installation
        directory, but anywhere will do.
        For a request with <literal>Host: example.com</literal>,
        attempt to serve from <literal>sitesDir/example.com</literal>.
        There is no default; this must be explicitly set.
      '';
    };
    package = mkOption {
      type = package;
      default = pkgs.werc;
      defaultText = "pkgs.werc";
      example = literalExample ''
        pkgs.werc.override {
          plan9port = pkgs.plan9port-static
        }
      '';
      description = ''
        The werc derivation to be added to the system environment.
        It will be called with <literal>.override</literal> to
        populate <filename>etc</filename> in the werc installation
        directory according to the configuration.
      '';
    };
    wrappedPackage = mkOption {
      type = package;
      readOnly = true;
      description = ''
        The werc derivation specified in <literal>package</literal>,
        wrapped with this module's configuration options.
        This option is to provide the effective derivation for
        whatever ends up calling werc as a CGI script, though more
        creative uses are imaginable.
      '';
    };
  };

  config = mkIf cfg.enable (let
    etcpop' = {
      inherit (cfg) users;
      initrc = lib.concatStringsSep "\n" [
        "sitesdir=${cfg.sitesDir}"
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
