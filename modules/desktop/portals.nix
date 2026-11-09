_: {
  flake.modules.homeManager.portals =
    {
      config,
      pkgs,
      ...
    }:
    {
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
          xdg-desktop-portal-termfilechooser
        ];
        config.common = {
          default = [ "gtk" ];
          # The file chooser is a terminal window, not a dialog; see
          # context/legion-desktop.md for why the KDE backend it replaced is
          # gone.
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [
            "gnome"
            "gtk"
          ];
        };
      };

      # The backend runs the wrapper in a terminal and reads the selection back
      # from the file the wrapper writes. `last` is the only last-location
      # memory in the chain: the frontend forwards whatever folder a client
      # suggests and the GTK backend keeps none, so the backend's own
      # $XDG_STATE_HOME record is what makes the chooser open where it last was.
      xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd = ${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir = ${config.home.homeDirectory}
        open_mode = last
        save_mode = last
        env = TERMCMD=kitty --class yazi-chooser
      '';

      # HM's xdg.portal adds extraPortals to home.packages but not
      # systemd.user.packages, which is where systemd finds the units.
      systemd.user.packages = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        xdg-desktop-portal-termfilechooser
      ];

      home.packages = [ pkgs.wl-clipboard ];

      xdg.terminal-exec = {
        enable = true;
        settings.default = [ "kitty.desktop" ];
      };

      # uwsm's systemd user session reads environment.d; home.sessionVariables
      # would only reach login shells.
      systemd.user.sessionVariables = {
        QT_QPA_PLATFORM = "wayland";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GTK_USE_PORTAL = "1";
        TERMINAL = "kitty";
      };
    };
}
