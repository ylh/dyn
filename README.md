`dyn` - kind of like a flake but not really
===========================================

This is my personal module that I pass around from place to place. Its purpose
is roughly:

* create the system configuration through automatic discovery within the
  config directory
* enforce some degree of layout convention in doing so
* extend `lib` and make those extensions accessible to modules
* pin everything that is auxiliary to the single system channel

Flakes could achieve everything this module does more intelligently and more
consistently, but they're not first-class everywhere yet; for instance, on
`nix-darwin`, a bootstrapping process is still required.

Basic Usage
-----------

Put this directory next to your `configuration.nix`, in which you set:

    imports = import ./dyn {};
    
Something more involved on, say, a stable NixOS, might be:

    imports = import ./dyn {
      unstable = /* your pinned nixos-unstable here */;
      imports = [ "${/* your pinned home-manager here */}/nixos" ];
    };
    
In either case, you read that right - `dyn` presents as a list containing
the real `dyn` module by default; it's just cleaner that way. Once you've done
this, `dyn` will bring in everything it finds, including
`hardware-configuration.nix`. More concretely, `import ./dyn {}` will
evaluate to something that looks like this:

    # paths are relative to your config directory
    # see defaultExcludes in the list of options below
    [ ({ lib, pkgs, ... }: {
      imports = (/* contents of ./dyn/modules */)
             ++ (/* contents of ./ except for excludes */);
      config.nixpkgs.overlays = (/* contents of ./dyn/overlays */)
                             ++ (/* contents of ./overlays */);
    }) ]

All the modules in `imports` become modified such that when called by the
module system, `lib` is replaced by a `lib` that has been extended with
`./dyn/mylib`, which is full of miscellaneous utilities.

Import Parameters
-----------------

`contrib`
: The search path outside of `dyn`. Default: `../.` (as seen by
`dyn/default.nix`)

`excl`
: Basenames of nix files to exclude if found. Default: `[]`

`defaultExcludes`
: Whether to append the default list of excludes to `excl`. These are
`configuration.nix`, `darwin-configuration.nix`, `home.nix`, and `overlays`.
Regardless of this option, if `contrib` is left at its default, `dyn` will
*always* be appended to `excl`. Default: `true`

`imports`
: Additional explicit imports, typically nix store paths for pinned external
modules. These need not be paths; they can be anything accepted by an `imports`
list in a standard module (i.e. literal module definitions, with or without
parameters). Default: `[]`

`unstable`
: The import path of an unstable nixpkgs, which becomes available as
`unstablePath` in `pkgs` by way of an overlay. Default: `null`

`others`
: Prevent `dyn` from wrapping itself in a list when imported, Default: `false`

How It Works
------------

The search process is specified in `lib.nixFiles`, which is defined and 
documented in `mylib/default.nix`. Roughly speaking, though, a given file tree
is traversed, terminating at any file with a `.nix` extension, or any directory
containing a `default.nix`. Regular files that don't end in `.nix` are ignored;
directories without a `default.nix` are descended into.

The collection of leaves is flattened into a list of import paths for modules,
or a list of imported values in the case of overlays. Overlays are expected
to evaluate to individual overlay functions, not lists of them.

Because directories containing `default.nix` are considered black boxes by this
system, they are the canonical means of sidestepping it. Anything in those
directories is safe from its prying eyes unless explicitly used in that
`default.nix`.

Considerations
--------------

The process of “enhancing” modules prior to import puts their canonical
definition site at the imports list of `dyn/default.nix`, not their respective
file paths. On occasion, this can make error messages more cryptic, though
the Nix module system uses robust metadata and this usually isn't an issue.

Please do not consider the contents of `dyn/{modules,overlays,mylib}` to be
immutable or set in stone; hack away. This is a personal project, and your
needs are likely not the same as mine. The intention for the directories inside
`dyn` is that they are shared between all the systems you work with, and the
contents of the `contrib` path are site-specific.

Unfortunately, I can't document everything. The authoritative documentation
is the source. That being said, the contents of `dyn/{modules,overlays,mylib}`
give some good hints as to intended usage.

Lastly
------

This is a hack. A hack that attempts to discipline itself to the useful minimum
of magic, but a hack nonetheless. This is a style of usage that is antithetical
to some design intent of Nix/NixOS I've seen expressed, the same design intent
that says there is no `eval`, only composing `builtins.import` and
`builtins.toFile`, the same design intent that says automatic config file
discovery seems like a horrible idea. It probably is a horrible idea for any
real-world deployment that is not a personal workstation or server. Warranty
disclaimers in licenses were written for this sort of thing. However, this
whole mess makes my experience configuring my personal machines more pleasant,
and in sharing it, my hope is that it does the same for you. Have fun!
