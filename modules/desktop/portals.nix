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
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [
            "wlr"
            "gnome"
            "gtk"
          ];
        };
      };

      # HM's xdg.portal adds extraPortals to home.packages but not
      # systemd.user.packages - the store units are invisible to systemd
      # on non-NixOS (no /etc/profiles/per-user/ fallback).
      systemd.user.packages = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        kdePackages.xdg-desktop-portal-kde
        xdg-desktop-portal-wlr
      ];

      home.packages = [ pkgs.wl-clipboard ];

      # ponytail: on NixOS UWSM pulls these from the systemd user env via the
      # NixOS UWSM module; on Arch the imperative ~/.config/uwsm/env still
      # sources them (hm-session-vars.sh isn't read by Arch's UWSM).
      home.sessionVariables = {
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "gtk3";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GTK_USE_PORTAL = "1";
        TERMINAL = "wezterm";
      };
    };
}
