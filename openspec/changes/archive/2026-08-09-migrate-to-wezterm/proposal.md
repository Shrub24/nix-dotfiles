## Why

WezTerm is already in use on the Arch host, but its configuration lives as a hand-maintained Lua file at `~/.config/wezterm/wezterm.lua` outside the Nix flake. Every other terminal tool in this repo (tmux, fish, etc.) is managed declaratively through Home Manager modules. WezTerm config should follow the same pattern so it is version-controlled, rebuildable, and co-located with the rest of the user configuration.

## What Changes

- Add a new Home Manager module `modules/home/wezterm.nix` that uses `programs.wezterm` to manage WezTerm configuration declaratively.
- Migrate the existing Lua config into Home Manager-managed WezTerm configuration:
  - `programs.wezterm.settings` for simple key-value settings (font_size, color_scheme, window_decorations, etc.)
  - `programs.wezterm.extraConfig` for Lua code that requires the WezTerm API (plugin loading, event handlers, tabline setup, key bindings with actions)
  - a preserved runtime reference to the existing dynamic `~/.config/wezterm/colors/dank-theme.toml` file, which WezTerm watches and reloads
- Add the new module to `modules/default.nix` imports.
- Optionally manage the WezTerm package itself through Home Manager if the user wants to switch from the Arch-packaged binary.

## Capabilities

### New Capabilities

- `wezterm-config`: The repository manages WezTerm terminal configuration declaratively through Home Manager, including settings, Lua extra config, dynamic theme references, and key bindings.

### Modified Capabilities

- None.

## Impact

- Adds `modules/home/wezterm.nix` and updates `modules/default.nix`.
- The existing `~/.config/wezterm/wezterm.lua` will be replaced by a Home Manager-managed equivalent, while `~/.config/wezterm/colors/dank-theme.toml` remains the live dynamic theme file.
- Config content is preserved — the same plugins, dynamic color theme reference, key bindings, and settings are declared through Home Manager rather than a hand-maintained Lua file.
