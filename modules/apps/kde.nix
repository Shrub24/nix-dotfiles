_: {
  flake.modules.homeManager.kde-apps =
    { pkgs, ... }:
    {
      services.kdeconnect.enable = true;

      qt = {
        enable = true;
        platformTheme.name = "gtk3";
      };

      home.packages =
        with pkgs;
        with pkgs.kdePackages;
        [
          # apps
          dolphin
          dolphin-plugins
          okular
          ark
          gwenview
          kdialog
          haruna
          systemsettings
          # dolphin I/O slaves (network protocols, recent files)
          kio-extras
          kio-fuse
          # thumbnailers (video, image, PDF previews in dolphin)
          ffmpegthumbs
          ffmpegthumbnailer
          kdegraphics-thumbnailers
        ];

      # breeze-icons intentionally omitted — user runs Sweet-Rainbow (via matugen);
      # add kdePackages.breeze-icons here if KDE-specific icons break.
    };

  flake.modules.nixos.kde-apps = _: {
    # Deliberate exception to the tailnet-only exposure policy: KDE Connect needs
    # LAN peers, so programs.kdeconnect opens 1714-1764 tcp/udp.
    programs.kdeconnect = {
      enable = true;
      package = null;
    };
  };
}
