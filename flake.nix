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
    nvfetcher = {
      url = "github:berberman/nvfetcher";
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
              nvfetcher
            ];
            NIX_CONFIG = "experimental-features = nix-command flakes";
          };

          apps.nvfetcher-update = {
            type = "app";
            program =
              let
                nvfu = pkgs.writeShellScriptBin "nvfetcher-update" ''
                  exec ${pkgs.nvfetcher}/bin/nvfetcher \
                    -c nvfetcher.toml \
                    -o pkgs/_sources \
                    "$@"
                '';
              in
              "${nvfu}/bin/nvfetcher-update";
            meta.description = "Run nvfetcher to update pkgs/_sources/generated.nix and generated.json";
          };
        };

      flake =
        let
          system = "x86_64-linux";
          agentmemorySources = import ./pkgs/agentmemory/sources.nix;
          overlay =
            final: prev:
            let
              generatedSources = import ./pkgs/_sources/generated.nix {
                inherit (final)
                  fetchgit
                  fetchurl
                  fetchFromGitHub
                  dockerTools
                  ;
              };
            in
            {
              snip = final.callPackage ./pkgs/snip {
                inherit (generatedSources.snip) version src;
              };
              nix-search-tv-fzf = final.callPackage ./pkgs/nix-search-tv-fzf { };
              iii-engine = final.callPackage ./pkgs/iii-engine {
                inherit (agentmemorySources."iii-engine") version;
                hash = agentmemorySources."iii-engine".srcHash;
                initHash = agentmemorySources."iii-engine".initHash;
                workerHash = agentmemorySources."iii-engine".workerHash;
              };
              agentmemory = final.callPackage ./pkgs/agentmemory {
                inherit (agentmemorySources.agentmemory) version npmDepsHash;
                srcHash = agentmemorySources.agentmemory.srcHash;
              };
              kreuzberg-cli = final.callPackage ./pkgs/kreuzberg-cli {
                inherit (generatedSources.kreuzberg-cli) version src;
              };
              headroom-ai = final.python3Packages.callPackage ./pkgs/headroom-ai {
                inherit (generatedSources.headroom-ai) version;
              };
              litellm-with-headroom = final.callPackage ./pkgs/litellm-with-headroom {
                headroom = final.headroom-ai;
              };
              niks3-hook = inputs.niks3.packages.${system}.niks3-hook;
            };
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
          commonSpecialArgs = {
            inherit inputs;
            repoRoot = "/home/saurabhj/.dotfiles/nix";
            appsDir = "/home/saurabhj/.dotfiles/apps";
          };
        in
        {
          homeConfigurations.saurabhj = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = commonSpecialArgs;
            modules = [
              ./hosts/arch/home.nix
              {
                programs.pi.package = inputs.llm-agents.packages.${system}.pi;
              }
            ];
          };

          systemConfigs.arch = inputs.system-manager.lib.makeSystemConfig {
            modules = [ ./hosts/arch/system.nix ];
            specialArgs = commonSpecialArgs;
            overlays = [ overlay ];
          };
        };
    };
}
