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
    pi-extensions = {
      url = "github:Shrub24/pi-extensions";
      flake = false;
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
    keypeek = {
      url = "github:srwi/keypeek";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.fenix.follows = "fenix";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
  };
}
