{ lib, ... }:
{
  # nix-fleet is the fleet's platform repository and the authority for the pins
  # both repositories share: one nix-fleet bump moves them together instead of
  # letting each repository drift on its own copy.
  flake-file.inputs = {
    flake-file.url = "github:denful/flake-file";
    nix-fleet.url = "github:Shrub24/nix-fleet";

    # Shares these pins with nix-fleet. The url defaults that flake-file's
    # presets carry are emptied so the generated flake.nix declares the follow
    # alone instead of a url that would never be used.
    nixpkgs = {
      url = lib.mkForce "";
      follows = "nix-fleet/nixpkgs";
    };
    flake-parts = {
      url = lib.mkForce "";
      follows = "nix-fleet/flake-parts";
    };
    import-tree = {
      url = lib.mkForce "";
      follows = "nix-fleet/import-tree";
    };
    treefmt-nix.follows = "nix-fleet/treefmt-nix";

    home-manager.url = "github:nix-community/home-manager/master";
    system-manager.url = "github:numtide/system-manager";

    # Package layer: consumed by pkgs/ recipes rather than by one feature.
    crane.url = "github:ipetkov/crane";
    fenix.url = "github:nix-community/fenix/monthly";
    keypeek.url = "github:srwi/keypeek";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };
}
