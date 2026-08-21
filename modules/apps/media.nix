_: {
  flake.modules.homeManager.media =
    { pkgs, ... }:
    {
      programs.obs-studio = {
        enable = true;
        package = pkgs.obs-studio.override { browserSupport = false; };
      };
      home.packages = with pkgs; [
        inkscape
        qbittorrent
        vesktop
      ];
    };
}
