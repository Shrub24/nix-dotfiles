{
  config,
  pkgs,
  ...
}: {
  home.username = "saurabhj";
  home.homeDirectory = "/home/saurabhj";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
