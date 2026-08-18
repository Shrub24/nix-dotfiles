_: {
  flake.modules.homeManager.kde-apps =
    { pkgs, ... }:
    {
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
          kdeconnect-kde
          systemsettings
          # dolphin I/O slaves (network protocols, recent files)
          kio-extras
          kio-fuse
          # thumbnailers (video, image, PDF previews in dolphin)
          ffmpegthumbs
          ffmpegthumbnailer
          kdegraphics-thumbnailers
          # Qt platform theme: gtk3 (QT_QPA_PLATFORMTHEME=gtk3 in portals.nix)
          # kvantum remains for qt6ct-style theming
          qt6ct
          qtstyleplugin-kvantum
        ];

      # ponytail: breeze-icons intentionally omitted — user runs Sweet-Rainbow
      # icon pack (in ~/.local/share/icons/ via matugen). If KDE-specific icons
      # break in dolphin/kdeconnect, add kdePackages.breeze-icons here.
    };
}
