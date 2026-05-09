{
  description = "saurabhj's Nix configuration — dendritic home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    direnv-instant.url = "github:Mic92/direnv-instant";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
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
            pkgs = inputs.nixpkgs.legacyPackages.${system};
          in
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = { inherit inputs; };
            modules = [ ./home/default.nix ];
          };
      };
    };
}
