_: {
  # nix-fleet is the fleet's platform repository and the authority for the pins
  # both repositories share: one nix-fleet bump moves them together instead of
  # letting each repository drift on its own copy. The remaining inputs are this
  # repository's own and are declared by the feature module that consumes them.
  flake-file.inputs = {
    nix-fleet.url = "github:Shrub24/nix-fleet";

    flake-file.follows = "nix-fleet/flake-file";

    nixpkgs.follows = "nix-fleet/nixpkgs";
    flake-parts = {
      follows = "nix-fleet/flake-parts";
      # nix-fleet's own lock already points its flake-parts at its nixpkgs.
      inputs.nixpkgs-lib.autoFollow = false;
    };
    import-tree.follows = "nix-fleet/import-tree";
    treefmt-nix = {
      follows = "nix-fleet/treefmt-nix";
      inputs.nixpkgs.autoFollow = false;
    };

    home-manager.url = "github:nix-community/home-manager/master";
    system-manager.url = "github:numtide/system-manager";

    # Package layer: consumed by pkgs/ recipes rather than by one feature.
    crane.url = "github:ipetkov/crane";
    fenix.url = "github:nix-community/fenix/monthly";
    keypeek.url = "github:srwi/keypeek";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };
}
