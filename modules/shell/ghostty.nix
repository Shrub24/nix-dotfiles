_: {
  flake.modules.homeManager.ghostty = _: {
    programs.ghostty = {
      enable = true;
      systemd.enable = false;

      # Palette rendered by the noctalia theme template into
      # ~/.config/ghostty/themes/noctalia (modules/desktop/noctalia.nix).
      settings = {
        theme = "noctalia";
        font-size = 14;
        font-family = "MapleMono";
        font-feature = "+calt";

        # herdr-radar's agent-icon font, mapped by codepoint rather than offered
        # as a fallback, so the icons resolve whatever the primary font is. The
        # family name stays unquoted: Ghostty reads it literally.
        font-codepoint-map = [
          "U+E1A0-U+E1B7=Herdr Agent Icons Max"
          "U+E1C0-U+E1C5=Herdr Agent Icons Max"
        ];

        window-decoration = false;
        window-padding-x = 12;
        window-padding-y = 12;
        background-opacity = 0.85;
        background-blur-radius = 64;

        cursor-style = "block";
        cursor-style-blink = true;

        scrollback-limit = 3023;

        mouse-hide-while-typing = true;
        copy-on-select = false;
        confirm-close-surface = false;

        app-notifications = "no-clipboard-copy,no-config-reload";

        keybind = [
          "ctrl+shift+n=new_window"
          "ctrl+t=new_tab"
          "ctrl+plus=increase_font_size:1"
          "ctrl+minus=decrease_font_size:1"
          "ctrl+zero=reset_font_size"
          "shift+enter=text:\\n"
        ];

        unfocused-split-opacity = 0.7;
        unfocused-split-fill = "#44464f";

        gtk-titlebar = false;

        shell-integration = "detect";
        shell-integration-features = "cursor,sudo,title,no-cursor";

        gtk-single-instance = true;

      };
    };
  };
}
