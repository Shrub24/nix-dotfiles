{ inputs, ... }:
{
  flake-file.inputs.monique.url = "github:ToRvaLDz/monique";
  flake-file.inputs.monique.inputs.nixpkgs.follows = "nixpkgs";

  # One gate for the whole Niri desktop: compositor config, its display-profile
  # daemon and the UWSM session entry.
  flake.modules.homeManager.niri =
    { pkgs, ... }:
    {
      imports = [
        ./_compositor.nix
        (import ./_monique.nix {
          moniquePackage = inputs.monique.packages.${pkgs.stdenv.hostPlatform.system}.default;
        })
      ];
    };

  flake.modules.nixos.niri = {
    imports = [ ./_session.nix ];
  };
}
