_: {
  flake.modules.homeManager.defaults = _: {
    # Desktop-wide default application associations, as desktop file IDs.
    # Reconciled with the live ~/.config/mimeapps.list on 2026-09-14: the browser
    # is Firefox there, so Firefox wins here too; Brave Origin keeps only the
    # chrome-scheme fallback. Telegram and Bruno desktop files do not exist on
    # this host, so their scheme handlers are not declared.
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

        # nvim is a pacman package (/usr/bin/nvim) whose desktop file lives in
        # /usr/share/applications — outside Nix, so referenced, not owned.
        "text/plain" = [ "nvim.desktop" ];

        "application/pdf" = [ "okularApplication_pdf.desktop" ];
        "inode/directory" = [ "org.kde.dolphin.desktop" ];
      };
    };
  };
}
