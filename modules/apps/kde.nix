_: {
  flake.modules.homeManager.kde-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; with pkgs.kdePackages; [
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
        # Qt platform theme: qt6ct hosts the kvantum style plugin
        # (QT_QPA_PLATFORMTHEME=qt6ct in portals.nix; select kvantum style in qt6ct)
        qt6ct
        qtstyleplugin-kvantum
      ];

      # ponytail: breeze-icons intentionally omitted — user runs Sweet-Rainbow
      # icon pack (in ~/.local/share/icons/ via matugen). If KDE-specific icons
      # break in dolphin/kdeconnect, add kdePackages.breeze-icons here.
    };
}
