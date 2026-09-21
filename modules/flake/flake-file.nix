{ inputs, ... }:
{
  # flake-file generates flake.nix from the input declarations in this tree;
  # the dendritic preset wires flake-parts + import-tree, and auto-follow keeps
  # nested `follows` in the generated file aligned with the root inputs.
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-file.flakeModules.auto-follow
  ];

  systems = [ "x86_64-linux" ];

  flake-file = {
    description = "saurabhj's Nix configuration — dendritic home-manager";

    nixConfig = {
      extra-substituters = [ "https://vicinae.cachix.org" ];
      extra-trusted-public-keys = [
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };
}
