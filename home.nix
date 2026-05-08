{
  config,
  lib,
  pkgs,
  ...
}:

let
  nixTools = with pkgs; [
    nh
    nil
    statix
    deadnix
    nixpkgs-fmt
    nix-tree
    nix-output-monitor
    nix-index
    nix-du
  ];
in
{
  home.username = "saurabhj";
  home.homeDirectory = "/home/saurabhj";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = nixTools;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = false;
  };
}
