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

      # ponytail: breeze-icons intentionally omitted — user runs Sweet-Rainbow
      # icon pack (in ~/.local/share/icons/ via matugen). If KDE-specific icons
      # break in dolphin/kdeconnect, add kdePackages.breeze-icons here.
    };

  flake.modules.nixos.kde-apps =
    { ... }:
    {
      programs.kdeconnect = {
        enable = true;
        package = null;
      };
    };
}
