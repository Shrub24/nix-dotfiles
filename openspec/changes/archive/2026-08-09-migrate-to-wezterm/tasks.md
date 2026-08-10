## 1. Create the WezTerm Home Manager module

- [x] 1.1 Create `modules/home/wezterm.nix` with `programs.wezterm.enable = true` and import it in `modules/default.nix`.
  - refs: `modules/home/tmux.nix`, `modules/default.nix`
  - criteria: the module is part of the Home Manager import tree and WezTerm config is managed by the flake
  - verify: `nix eval .#homeConfigurations.saurabhj.activationPackage.drvPath` succeeds with the new module

## 2. Preserve dynamic color scheme reference

- [x] 2.1 Preserve the dynamic `dank-theme` runtime reference to `~/.config/wezterm/colors/dank-theme.toml` instead of declaring theme colors in `programs.wezterm.colorSchemes`.
  - refs: `~/.config/wezterm/colors/dank-theme.toml`, `modules/home/wezterm.nix`
  - criteria: the Home Manager-managed Lua config watches and loads the same dynamic theme file, and theme colors are not hardcoded in Nix
  - verify: generated WezTerm config contains `wezterm.config_dir .. "/colors/dank-theme.toml"` and `wezterm.add_to_config_reload_watch_list(theme_path)`

## 3. Migrate simple settings

- [x] 3.1 Declare simple key-value settings in `programs.wezterm.settings`, including font (with `mkLuaInline` for `font_with_fallback`), font_size, color_scheme, window_decorations, window_background_opacity, line_height, initial_cols, use_fancy_tab_bar, freetype_load_target, freetype_render_target, warn_about_missing_glyphs, detect_password_input, adjust_window_size_when_changing_font_size, enable_kitty_keyboard, and ssh_domains.
  - refs: `~/.config/wezterm/wezterm.lua`, `modules/home/wezterm.nix`
  - criteria: all simple settings from the existing Lua file are expressed as Nix attributes in `programs.wezterm.settings`
  - verify: generated `wezterm.lua` contains the expected settings values

## 4. Migrate Lua-dependent config to extraConfig

- [x] 4.1 Move plugin loading, event handlers, key bindings, tabline setup, hyperlink_rules, and window_padding into `programs.wezterm.extraConfig` as Lua code.
  - refs: `~/.config/wezterm/wezterm.lua`, `modules/home/wezterm.nix`
  - criteria: all WezTerm API-dependent configuration from the existing Lua file is preserved in `extraConfig`
  - verify: the extraConfig Lua code loads plugins, sets up tabline, registers the toggle-opencode event handler, and declares the same key bindings

## 5. Validate and verify

- [x] 5.1 Validate the Home Manager configuration builds and the generated WezTerm config matches the existing behavior.
  - refs: `modules/home/wezterm.nix`, `flake.nix`
  - depends: 1.1, 2.1, 3.1, 4.1
  - criteria: Home Manager activation produces a valid `wezterm.lua` with settings and extraConfig present, and with the dynamic theme file still referenced at runtime
  - verify: `nix eval .#homeConfigurations.saurabhj.activationPackage.drvPath` succeeds
- [x] 5.2 Confirm the existing hand-maintained `wezterm.lua` can be replaced without taking ownership of the dynamic theme file.
  - refs: `~/.config/wezterm/wezterm.lua`, `~/.config/wezterm/colors/dank-theme.toml`
  - depends: 5.1
  - criteria: Home Manager-managed config replaces `wezterm.lua`, while `dank-theme.toml` remains available as the watched dynamic theme file
  - verify: after activation, WezTerm loads configuration from the Home Manager-managed path and continues to watch the existing theme path
