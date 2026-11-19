# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "saurabhj's Nix configuration — dendritic home-manager";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  nixConfig = {
    extra-substituters = [ "https://umbriel.cachix.org?priority=50" ];
    extra-trusted-public-keys = [ "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw=" ];
  };

  inputs = {
    agent-radar = {
      url = "github:Shrub24/agent-radar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    community-templates = {
      url = "github:noctalia-dev/community-templates";
      flake = false;
    };
    crane.url = "github:ipetkov/crane";
    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fish-abbreviation-tips = {
      url = "github:Gazorby/fish-abbreviation-tips";
      flake = false;
    };
    fish-replay = {
      url = "github:jorgebucaran/replay.fish";
      flake = false;
    };
    flake-file.follows = "nix-fleet/flake-file";
    flake-parts.follows = "nix-fleet/flake-parts";
    herdr-radar = {
      url = "github:Shrub24/herdr-radar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent/v0.22.4";
      inputs = {
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.follows = "nix-fleet/import-tree";
    keypeek = {
      url = "github:Shrub24/keypeek";
      inputs = {
        crane.follows = "crane";
        fenix.follows = "fenix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    magic-context = {
      url = "github:Shrub24/magic-context/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    memex = {
      url = "github:Shrub24/memex/deploy/live";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
      };
    };
    monique = {
      url = "github:ToRvaLDz/monique";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-fleet.url = "github:Shrub24/nix-fleet";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixbot.follows = "nix-fleet/nixbot";
    nixos-boot = {
      url = "github:Melkor333/nixos-boot";
      flake = false;
    };
    nixpkgs.follows = "nix-fleet/nixpkgs";
    nixpkgs-fork.url = "github:Shrub24/nixpkgs/8ec593ac99f7c500942d218389fa665a8fae6a46";
    nixpkgs-fork-codexbar.url = "github:Shrub24/nixpkgs/3908c4a4f26a2a4c373f42b77abec3cc6e92e1f4";
    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-bolt-nix = {
      url = "github:Shrub24/Pi-Bolt.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-extensions = {
      url = "github:Shrub24/pi-extensions";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pi-bolt-nix.follows = "pi-bolt-nix";
      };
    };
    pi-powerline-footer = {
      url = "github:Shrub24/pi-powerline-footer";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sweet = {
      url = "github:EliverLara/Sweet";
      flake = false;
    };
    treefmt-nix.follows = "nix-fleet/treefmt-nix";
    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.xdg-desktop-portal-umbriel.follows = "xdg-desktop-portal-umbriel";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae/v0.29.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae-extensions = {
      url = "github:Shrub24/vicinae-extensions";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        vicinae.follows = "vicinae";
      };
    };
    wrappers = {
      url = "github:nix-community/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xdg-desktop-portal-umbriel = {
      url = "github:Shrub24/xdg-desktop-portal-umbriel/fix/picker-parent-window";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
