## Overview

The existing WezTerm configuration is a 120-line Lua file that mixes simple settings (font_size, color_scheme), WezTerm API calls (plugin loading, event handlers, tabline setup), and a dynamic custom TOML color scheme. Home Manager's `programs.wezterm` module provides native settings generation plus raw Lua `extraConfig`; the dynamic theme file remains outside generated Nix so WezTerm can keep watching and reloading it at runtime.

## Decisions

### Use Home Manager settings plus extraConfig, but keep the dynamic theme file external
- **`programs.wezterm.settings`**: for simple key-value configuration that `lib.generators.toLua` can render (font_size, color_scheme, window_decorations, window_background_opacity, line_height, initial_cols, use_fancy_tab_bar, etc.).
- **`programs.wezterm.extraConfig`**: for Lua code that needs the WezTerm API — plugin loading (`wezterm.plugin.require`), event handlers (`wezterm.on`), tabline setup, smart_splits, key bindings using `wezterm.action`, and watching/loading `wezterm.config_dir .. "/colors/dank-theme.toml"`. The `extraConfig` Lua merges on top of `settings` and takes precedence on conflicts.
- **No `programs.wezterm.colorSchemes` for `dank-theme`**: the theme file is dynamic and already watched by the WezTerm config. The migration preserves a runtime reference to the same file rather than hardcoding theme colors in Nix.

### Preserve all existing config behavior
- The migrated config must produce the same effective WezTerm behavior as the current Lua file: same fonts, same plugins, same color scheme, same key bindings, same SSH domains, same tabline appearance, same opencode toggle event.
- Plugin loading (`resurrect`, `smart_workspace_switcher`, `wezterm-replay`, `tabline.wez`, `smart-splits.nvim`) stays in `extraConfig` because it requires `wezterm.plugin.require` which cannot be expressed as a Nix attribute.

### Keep the WezTerm package optional
- The user currently runs WezTerm installed via Arch/pacman. The module should allow package management via Home Manager (`programs.wezterm.package`) but not force a switch in this change unless the user opts in.

## Config Breakdown

| Existing Lua section            | Home Manager surface          | Notes                                                          |
| ------------------------------ | ----------------------------- | -------------------------------------------------------------- |
| `config.font` (font_with_fallback) | `settings.font` with `mkLuaInline` | Needs raw Lua for `wezterm.font_with_fallback`               |
| `config.font_size`               | `settings.font_size`           | Simple value                                                    |
| `config.color_scheme`            | `settings.color_scheme`         | Simple string, references the dynamic theme by name             |
| `config.window_decorations`      | `settings.window_decorations`  | Simple string                                                   |
| `config.window_background_opacity` | `settings.window_background_opacity` | Simple float                                               |
| `config.line_height`             | `settings.line_height`          | Simple float                                                    |
| `config.initial_cols`            | `settings.initial_cols`         | Simple integer                                                  |
| `config.use_fancy_tab_bar`       | `settings.use_fancy_tab_bar`   | Simple boolean                                                  |
| `config.warn_about_missing_glyphs` | `settings.warn_about_missing_glyphs` | Simple boolean                                          |
| `config.detect_password_input`   | `settings.detect_password_input` | Simple boolean                                                |
| `config.adjust_window_size_when_changing_font_size` | `settings.adjust_window_size_when_changing_font_size` | Simple boolean           |
| `config.enable_kitty_keyboard`   | `settings.enable_kitty_keyboard` | Simple boolean                                                |
| `config.hyperlink_rules`         | `extraConfig`                  | Needs `wezterm.default_hyperlink_rules()`                       |
| `config.keys` (key bindings)     | `extraConfig`                  | Uses `wezterm.action` and custom event emission                |
| `config.ssh_domains`             | `settings.ssh_domains`         | List of attribute sets — should be expressible in Nix          |
| `config.window_padding.left`     | `extraConfig`                  | String value `"0.25cell"` — Lua string, safer in extraConfig   |
| `config.freetype_load_target`    | `settings.freetype_load_target` | Simple string                                                  |
| `config.freetype_render_target`  | `settings.freetype_render_target` | Simple string                                                |
| Plugin loading (resurrect, workspace_switcher, wezterm-replay, tabline, smart-splits) | `extraConfig` | Requires `wezterm.plugin.require` |
| `wezterm.on("toggle-opencode", ...)` | `extraConfig`              | Event handler with Lua state                                    |
| `tabline.setup` and `tabline.set_theme` | `extraConfig`           | Complex Lua with wezterm API calls                             |
| Color scheme (dank-theme.toml)   | external watched file referenced from `extraConfig` | Keep `wezterm.config_dir .. "/colors/dank-theme.toml"` dynamic |

## Risks and Mitigations

- **Lua generation quirks**: `lib.generators.toLua` may not perfectly render all value types. Mitigate by using `mkLuaInline` for raw Lua where needed, and verify the generated `wezterm.lua` matches the expected output.
- **Plugin URL changes**: Plugin loading uses `wezterm.plugin.require` with GitHub URLs that are cached at runtime. This stays in `extraConfig` and is unchanged from the current Lua.
- **Dynamic theme ownership**: The theme file intentionally remains outside Home Manager colorSchemes so external/theme-generation workflows can update it and WezTerm can reload it via the existing watch path.
