{
  config,
  ...
}:
let
  # Typed remote-host topology read at the flake-parts level (B5); closed over
  # by the lower-level HM module.
  remoteHosts = config.topology.hosts.arch.remoteHosts;
in
{
  flake.modules.homeManager.wezterm =
    {
      lib,
      ...
    }:

    {
      programs.wezterm = {
        enable = true;

        settings = {
          font = lib.generators.mkLuaInline ''
            wezterm.font_with_fallback({
              { family = "Maple Mono NF", harfbuzz_features = { "calt=1", "clig=1", "liga=1" } },
              "JetBrains Mono",
              "Fira Code",
            })
          '';
          font_size = 15.0;
          color_scheme = "dank-theme";
          window_background_opacity = 0.8;
          line_height = 1.0;
          initial_cols = 120;
          use_fancy_tab_bar = false;
          freetype_load_target = "HorizontalLcd";
          freetype_render_target = "HorizontalLcd";
          warn_about_missing_glyphs = false;
          detect_password_input = true;
          adjust_window_size_when_changing_font_size = false;
          enable_kitty_keyboard = false;
          ssh_domains = map (name: {
            inherit name;
            remote_address = name;
          }) remoteHosts;
        };

        extraConfig = ''
          local act = wezterm.action

          -- Plugin loading
          local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
          local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
          workspace_switcher.apply_to_config(config)
          local wezterm_replay = wezterm.plugin.require("https://github.com/btrachey/wezterm-replay")
          wezterm_replay.apply_to_config(config)

          -- Dynamic color scheme: keep using the live file so external theme updates are watched/reloaded.
          local theme_path = wezterm.config_dir .. "/colors/dank-theme.toml"
          wezterm.add_to_config_reload_watch_list(theme_path)
          config.colors, _ = wezterm.color.load_scheme(theme_path)

          -- Tabline plugin
          local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
          tabline.setup({
            options = {
              theme = config.colors,
              section_separators = {
                left = wezterm.nerdfonts.ple_right_half_circle_thick,
                right = wezterm.nerdfonts.ple_left_half_circle_thick,
              },
              component_separators = {
                left = wezterm.nerdfonts.ple_right_half_circle_thin,
                right = wezterm.nerdfonts.ple_left_half_circle_thin,
              },
              tab_separators = {
                left = wezterm.nerdfonts.ple_right_half_circle_thick,
                right = wezterm.nerdfonts.ple_left_half_circle_thick,
              },
            },
            sections = {
              tabline_a = { "mode" },
              tabline_b = { { padding = { left = 1, right = 0 }, "workspace" } },
              tabline_c = { "     " },
              tab_active = {
                { "index", zero_indexed = false },
                { "process", padding = { left = 0, right = 0 } },
                "/",
                { "cwd", padding = { left = 0, right = 1 } },
                { "zoomed", padding = 0 },
                max_length = 15,
              },
              tab_inactive = {
                "index",
                { "process", icons_only = true, padding = 0 },
                { "cwd", padding = { left = 0, right = 1 } },
                max_length = 8,
              },
              tabline_x = { "datetime" },
              tabline_y = { "battery" },
              tabline_z = { "hostname" },
            },
            extensions = { "resurrect", "smart_workspace_switcher" },
          })
          tabline.apply_to_config(config)

          -- Window padding
          config.window_padding.left = "0.25cell"

          -- Tabline theme colors
          local z_theme = { bg = config.colors.brights[3], fg = config.colors.ansi[1] }
          local x_theme = { bg = config.colors.ansi[4], fg = config.colors.ansi[1] }
          tabline.set_theme({
            normal_mode = { y = x_theme, b = x_theme },
            tab = {
              inactive = { bg = config.colors.ansi[1], fg = config.colors.brights[3] },
              active = { bg = config.colors.brights[2], fg = config.colors.ansi[1] },
            },
          })
          tabline.refresh()

          -- Smart splits
          local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
          smart_splits.apply_to_config(config)

          -- Opencode toggle event handler
          local opencode_panes = {}
          wezterm.on("toggle-opencode", function(window, pane)
            wezterm.log_info("toggle-opencode fired, tab=", window:active_tab():tab_id())
            local tab_id = window:active_tab():tab_id()
            local target_pane_id = opencode_panes[tab_id]
            local target_pane = target_pane_id and wezterm.mux.get_pane(target_pane_id)
            if target_pane then
              wezterm.log_info("Closing existing opencode pane ", target_pane_id)
              target_pane:close()
              opencode_panes[tab_id] = nil
            else
              local shell = os.getenv("SHELL") or "bash"
              wezterm.log_info("Opening opencode pane with shell: ", shell)
              local new_pane = pane:split({ direction = "Right", size = 0.5, args = { shell, "-ic", "opencode" } })
              opencode_panes[tab_id] = new_pane:pane_id()
            end
          end)

          -- Re-apply settings after plugins to prevent them from being clobbered
          config.window_decorations = "NONE"

          -- Hyperlink rules
          config.hyperlink_rules = wezterm.default_hyperlink_rules()

          -- Key bindings
          config.keys = {
            { key = "A", mods = "CTRL|SHIFT", action = act.EmitEvent("toggle-opencode") },
            { key = "S", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs { flags = "DOMAINS" } },
            { key = "Delete", mods = "NONE", action = act.SendString("\x1b[3~") },
          }
        '';
      };
    }

  ;
}
