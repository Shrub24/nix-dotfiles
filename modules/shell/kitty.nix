_: {
  flake.modules.homeManager.kitty = {
    programs.kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;

      # Palette rendered by the noctalia theme template into
      # ~/.config/kitty/themes/noctalia.conf (modules/desktop/noctalia.nix); the
      # include below picks it up (kitty reloads includes on SIGUSR1).
      settings = {
        font_family = "Maple Mono NF";
        font_size = 14;

        background_opacity = "0.85";
        background_blur = 1;
        window_padding_width = 12;
        hide_window_decorations = "yes";

        cursor_shape = "block";
        scrollback_lines = 3023;
        confirm_os_window_close = 0;
        update_check_interval = 0;
        repaint_delay = 5;
        input_delay = 2;

        paste_actions = "quote-urls-at-prompt,confirm";
        clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
        notify_on_cmd_finish = "unfocused";
      };

      extraConfig = "include themes/noctalia.conf";
    };
  };
}
