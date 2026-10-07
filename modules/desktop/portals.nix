_: {
  flake.modules.homeManager.portals =
    { pkgs, ... }:
    {
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
          kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-wlr
        ];
        config.common = {
          default = [
            "kde"
            "gtk"
          ];
          # KDE and the frontend deadlock on each other's startup for 26 s; see context/legion-desktop.md.
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [
            "wlr"
            "gnome"
            "gtk"
          ];
        };
      };

      # HM's xdg.portal adds extraPortals to home.packages but not
      # systemd.user.packages, which is where systemd finds the units.
      systemd.user.packages = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        kdePackages.xdg-desktop-portal-kde
        xdg-desktop-portal-wlr
      ];

      home.packages = [ pkgs.wl-clipboard ];

      # uwsm's systemd user session reads environment.d; home.sessionVariables
      # would only reach login shells.
      systemd.user.sessionVariables = {
        QT_QPA_PLATFORM = "wayland";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GTK_USE_PORTAL = "1";
        TERMINAL = "wezterm";
      };
    };
}
