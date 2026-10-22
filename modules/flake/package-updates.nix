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
        # Regenerate the plugin lock from the pins already in the tree: the step to
        # run after a pi-extensions bump. A pin move regenerates it within the
        # package updater's own run.
        update-plugin-lock = repoPkgs.pi-plugins.passthru.updateLock;
      };
    };
}
