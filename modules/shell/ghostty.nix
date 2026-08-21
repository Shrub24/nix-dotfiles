_: {
  flake.modules.homeManager.ghostty = _: {
    programs.ghostty = {
      enable = true;
      systemd.enable = false;

      themes.dankcolors = {
        background = "#1e0f13";
        foreground = "#f8dbe1";
        cursor-color = "#ffb1c6";
        selection-background = "#ce066a";
        selection-foreground = "#f8dbe1";
        palette = [
          "0=#1e0f13"
          "1=#d15f37"
          "2=#6ed687"
          "3=#ccdb7b"
          "4=#cf5c79"
          "5=#bf909d"
          "6=#ffb1c6"
          "7=#abb2bf"
          "8=#5c6370"
          "9=#e0805f"
          "10=#86e09b"
          "11=#dbe897"
          "12=#ffbdd4"
          "13=#b95a82"
          "14=#ae646e"
          "15=#ffffff"
        ];
      };

      settings = {
        theme = "dankcolors";
        font-size = 14;
        font-family = "MapleMono";
        font-feature = "+calt";

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
