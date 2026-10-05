{ inputs, ... }:
{
  # Core flake-file module, not the dendritic preset: auto-follow rewrites
  # `follows` through flake-edit; see ARCHITECTURE.md.
  imports = [
    inputs.flake-file.flakeModules.default
  ];

  systems = [ "x86_64-linux" ];

  flake-file = {
    description = "saurabhj's Nix configuration — dendritic home-manager";
    outputs = "dendritic";
  };
}
