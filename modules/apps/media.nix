_: {
  flake.modules.homeManager.media =
    { pkgs, ... }:
    {
      # ponytail: browserSupport off — cef-binary is ~1.95 GiB and only needed
      # for browser sources (streaming). Screen capture + controls work without
      # it; re-enable if a browser source is ever required.
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
