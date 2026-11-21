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

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
  };
}
