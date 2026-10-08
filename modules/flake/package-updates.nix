{ inputs, ... }:
{
  imports = [ inputs.nix-fleet.flakeModules.packageUpdates ];

  perSystem =
    { pkgs, system, ... }:
    let
      repoPkgs = pkgs.extend (import ../../pkgs { inherit inputs system; });
    in
    {
      packageUpdates.packages = [
        "pi-bolt"
        "pi-plugins"
        "xberg-cli"
        "codexbar"
      ];
      packages = {
        inherit (repoPkgs) pi-plugins xberg-cli codexbar;
      };
    };
}
