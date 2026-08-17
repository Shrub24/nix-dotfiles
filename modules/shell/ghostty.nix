_: {
  flake.modules.homeManager.ghostty =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ghostty ];

      # ponytail: config-file=./config-dankcolors still loads the
      # DMS/matugen-generated file at runtime — left mutable (unmanaged) for now;
      # likely owned by Noctalia or replaced in a later round.
      xdg.configFile."ghostty/config".text = ''
        font-size = 14
        font-family = MapleMono
        font-feature = +calt

        window-decoration = false
        window-padding-x = 12
        window-padding-y = 12
        background-opacity = 0.85
        background-blur-radius = 64

        cursor-style = block
        cursor-style-blink = true

        scrollback-limit = 3023

        mouse-hide-while-typing = true
        copy-on-select = false
        confirm-close-surface = false

        app-notifications = no-clipboard-copy,no-config-reload

        keybind = ctrl+shift+n=new_window
        keybind = ctrl+t=new_tab
        keybind = ctrl+plus=increase_font_size:1
        keybind = ctrl+minus=decrease_font_size:1
        keybind = ctrl+zero=reset_font_size

        unfocused-split-opacity = 0.7
        unfocused-split-fill = #44464f

        gtk-titlebar = false

        shell-integration = detect
        shell-integration-features = cursor,sudo,title,no-cursor
        keybind = shift+enter=text:\n

        gtk-single-instance = true

        config-file = ./config-dankcolors
      '';
    };
}
