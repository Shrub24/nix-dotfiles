_: {
  # flake-parts and treefmt-nix ship a nested nixpkgs, already redirected by
  # their nix-fleet follows.
  flake-file.inputs = {
    nix-fleet.url = "github:Shrub24/nix-fleet";

    flake-file.follows = "nix-fleet/flake-file";

    nixpkgs.follows = "nix-fleet/nixpkgs";
    flake-parts.follows = "nix-fleet/flake-parts";
    import-tree.follows = "nix-fleet/import-tree";
    treefmt-nix.follows = "nix-fleet/treefmt-nix";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Package layer: consumed by pkgs/ recipes rather than by one feature.
    # The plugin set is consumed through its flake output — per-plugin packages,
    # or `overlays.default` for the whole set. It builds against Pi-Bolt.nix, so
    # its input follows ours: one builder, one release, for the plugins and for
    # the payload that compiles them in.
    pi-extensions = {
      url = "github:Shrub24/pi-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pi-bolt-nix.follows = "pi-bolt-nix";
    };
    pi-powerline-footer = {
      url = "github:Shrub24/pi-powerline-footer";
      flake = false;
    };
    magic-context = {
      url = "github:Shrub24/magic-context/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pi-Bolt compiled ahead of time with the plugins a Nix expression selects.
    # The interface this repository adopted while it was proposed upstream now
    # lives in its own repository, which also owns the release it builds, the
    # runtime that release needs, and the docs for both: its README,
    # docs/guides/plugins.md (plugins, withPlugins) and docs/contributing/releases.md.
    pi-bolt-nix = {
      url = "github:Shrub24/Pi-Bolt.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pi-bolt-source.follows = "pi-bolt-source";
    };

    # The compiled source: the pinned release plus the request-model change
    # (earendil-works/pi#10318), carried as a fork branch so the source is a
    # plain input. A patched derivation in its place is read during evaluation,
    # which the fleet's CI refuses.
    pi-bolt-source = {
      url = "github:Shrub24/Pi-Bolt/request-model";
      flake = false;
    };

    # Shrub24/nixpkgs fork carrying packages pending upstream review. No follows:
    # its packages build against the fork's own pins, so the derivation under test
    # is the one proposed upstream.
    nixpkgs-fork = {
      url = "github:Shrub24/nixpkgs/8ec593ac99f7c500942d218389fa665a8fae6a46";
    };
    nixpkgs-fork-codexbar = {
      url = "github:Shrub24/nixpkgs/3908c4a4f26a2a4c373f42b77abec3cc6e92e1f4";
    };

    # Plymouth theme source built by pkgs/nixos-boot (boot.nix selects it).
    nixos-boot = {
      url = "github:Melkor333/nixos-boot";
      flake = false;
    };

    # Disk layout capture for install day (written but unimported until the
    # bare-metal install; see modules/hosts/legion/_disko.nix).
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # crane declares no inputs of its own, so it has no nested nixpkgs to redirect.
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The fork carries the package assets (desktop entry, icon, udev rule) and
    # the Home Manager module this repository configures.
    keypeek = {
      url = "github:Shrub24/keypeek";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.fenix.follows = "fenix";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    # Vicinae extensions and the capture CLI they front; behaviour and the
    # launcher surface that presents it version together there.
    vicinae-extensions = {
      url = "github:Shrub24/vicinae-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      # The extensions build against the launcher that serves them, not a second
      # checkout of their own; following it also carries its nixpkgs.
      inputs.vicinae.follows = "vicinae";
    };
  };
}
