_: {
  # nix-fleet is the fleet's platform repository and the authority for the pins
  # both repositories share: one nix-fleet bump moves them together instead of
  # letting each repository drift on its own copy. The remaining inputs are this
  # repository's own and are declared by the feature module that consumes them.
  #
  # flake-parts and treefmt-nix are the only inputs here that ship their own
  # nested nixpkgs alongside a fleet pin, so neither declares a follows.
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
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      # userborn sits two deep and carries its own flake-parts.
      inputs.userborn.inputs.flake-parts.follows = "flake-parts";
    };

    # Package layer: consumed by pkgs/ recipes rather than by one feature.
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
