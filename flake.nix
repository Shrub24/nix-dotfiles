{
  description = "saurabhj's Nix configuration — dendritic home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    direnv-instant.url = "github:Mic92/direnv-instant";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    monique = {
      url = "github:ToRvaLDz/monique";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
    };
    hermes-agent-src = {
      url = "github:yzx9/hermes-agent/feat/home-manager";
      flake = false;
    };
    codebase-memory-mcp = {
      url = "github:DeusData/codebase-memory-mcp";
    };
    niks3 = {
      url = "github:Mic92/niks3";
    };

    fish-abbreviation-tips = {
      url = "github:Gazorby/fish-abbreviation-tips";
      flake = false;
    };
    fish-autopair = {
      url = "github:jorgebucaran/autopair.fish";
      flake = false;
    };
    fish-done = {
      url = "github:franciscolourenco/done";
      flake = false;
    };
    fish-replay = {
      url = "github:jorgebucaran/replay.fish";
      flake = false;
    };
    fish-sponge = {
      url = "github:meaningful-ooo/sponge";
      flake = false;
    };
    fsel = {
      url = "github:Mjoyufull/fsel";
    };
    keypeek = {
      url = "github:srwi/keypeek";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    surge = {
      url = "github:SurgeDM/Surge/v0.11.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ (inputs.import-tree ./modules) ];

      systems = [ "x86_64-linux" ];
    };
}
