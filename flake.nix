{
  description = "saurabhj's Nix configuration — dendritic home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    direnv-instant.url = "github:Mic92/direnv-instant";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
    fish-ai = {
      url = "github:Realiserad/fish-ai";
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
    fish-fifc = {
      url = "github:gazorby/fifc";
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
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt;

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nixd
              nil
              statix
              deadnix
              nixfmt
              nix-output-monitor
            ];
            NIX_CONFIG = "experimental-features = nix-command flakes";
          };
        };

      flake = {
        homeConfigurations.saurabhj =
          let
            system = "x86_64-linux";
            agentmemorySources = import ./pkgs/agentmemory/sources.nix;
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                (final: prev: {
                  snip = final.callPackage ./pkgs/snip { };
                  nix-search-tv-fzf = final.callPackage ./pkgs/nix-search-tv-fzf { };
                  iii-engine = final.callPackage ./pkgs/iii-engine {
                    inherit (agentmemorySources."iii-engine") version;
                    hash = agentmemorySources."iii-engine".srcHash;
                  };
                  agentmemory = final.callPackage ./pkgs/agentmemory {
                    inherit (agentmemorySources.agentmemory) version npmDepsHash;
                    srcHash = agentmemorySources.agentmemory.srcHash;
                  };
                  kreuzberg-cli = final.callPackage ./pkgs/kreuzberg-cli { };
                  niks3-hook = inputs.niks3.packages.${system}.niks3-hook;
                })
              ];
            };
          in
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit inputs;
              repoRoot = "/home/saurabhj/.dotfiles/nix";
              appsDir = "/home/saurabhj/.dotfiles/apps";
            };
            modules = [
              ./hosts/arch/home.nix
              {
                programs.pi.package = inputs.llm-agents.packages.${system}.pi;
              }
            ];
          };
      };
    };
}
