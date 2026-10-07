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
  };
}
