{ inputs, ... }:
{
  # flake-file generates flake.nix from the input declarations in this tree:
  # the core module supplies the flake-file.* options, the write-flake app and
  # checks.check-flake-file, and auto-follow keeps nested follows aligned with
  # the root inputs. The dendritic entry point is declared rather than imported
  # from flake-file's preset, so nothing sets a default url or follows that this
  # repository would have to override back out.
  imports = [
    inputs.flake-file.flakeModules.default
    inputs.flake-file.flakeModules.auto-follow
  ];

  systems = [ "x86_64-linux" ];

  flake-file = {
    description = "saurabhj's Nix configuration — dendritic home-manager";
    outputs = "dendritic";

    nixConfig = {
      extra-substituters = [ "https://vicinae.cachix.org" ];
      extra-trusted-public-keys = [
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };
}
