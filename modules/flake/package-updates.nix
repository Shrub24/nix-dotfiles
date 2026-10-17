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
        # Pi-Bolt's release pin lives in the flake that builds it, so its
        # version is bumped as an input rather than here.
        "pi-plugins"
        "xberg-cli"
        "codexbar"
      ];
      packages = {
        inherit (repoPkgs) pi-plugins xberg-cli codexbar;
        # The plugin lock's generator: run after a Pi-Bolt input bump or a plugin
        # pin change, since it resolves ranges against the registry.
        update-plugin-lock = repoPkgs.pi-plugins.passthru.updateLock;
      };
    };
}
