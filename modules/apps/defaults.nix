_: {
  flake.modules.homeManager.defaults = _: {
    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = [ "firefox.desktop" ];
        "text/xml" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "application/x-extension-htm" = [ "firefox.desktop" ];
        "application/x-extension-html" = [ "firefox.desktop" ];
        "application/x-extension-shtml" = [ "firefox.desktop" ];
        "application/x-extension-xht" = [ "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [
          "firefox.desktop"
          "brave-origin.desktop"
        ];

        "x-scheme-handler/discord" = [ "vesktop.desktop" ];
        "x-scheme-handler/geo" = [ "google-maps-geo-handler.desktop" ];

        "text/plain" = [ "nvim.desktop" ];

        "application/pdf" = [ "okularApplication_pdf.desktop" ];
        "inode/directory" = [ "org.kde.dolphin.desktop" ];
      };
    };

    # The directories file dialogs, KDE's Places and command-line tools resolve
    # through. Home Manager also renders user-dirs.conf with `enabled=False`, so
    # xdg-user-dirs-update cannot rewrite the declared mapping.
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      # The remaining directories rely on the module's defaults, which are the
      # standard `$HOME/<dir>` paths. There is no ~/Public on either host, so
      # that entry is omitted and the XDG default stands.
      publicShare = null;
      # The XDG_*_DIR session variables are not how anything here looks these
      # directories up, and the option's default moves with the state version.
      setSessionVariables = false;
    };
  };
}
