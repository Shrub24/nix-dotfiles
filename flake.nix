{
  description = "saurabhj's Nix configuration — dendritic home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
    codebase-memory-mcp = {
      url = "github:DeusData/codebase-memory-mcp";
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
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                (final: prev: {
                  tokf = final.callPackage ./pkgs/tokf { };
                  nix-search-tv-fzf = final.callPackage ./pkgs/nix-search-tv-fzf { };
                })
              ];
            };
          in
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = { inherit inputs; };
            modules = [
              ./hosts/arch/home.nix
              {
                programs.pi.package = inputs.llm-agents.packages.${system}.pi;
                programs.hermes.package = inputs.hermes-agent.packages.${system}.default;
              }
            ];
          };
      };
    };
}