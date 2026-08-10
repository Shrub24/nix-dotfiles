<!--
canonical-spec: wezterm-config
status: active
source-change: archive/2026-08-09-migrate-to-wezterm
source-spec: openspec/changes/archive/2026-08-09-migrate-to-wezterm/specs/wezterm-config/spec.md
-->

## Purpose

Defines the canonical requirements for declarative WezTerm configuration.
## Requirements
### Requirement: WezTerm configuration is managed declaratively through Home Manager
The repository SHALL manage WezTerm terminal configuration through a Home Manager module using `programs.wezterm` rather than a hand-maintained Lua file outside the flake.

#### Scenario: Maintainer reviews WezTerm configuration
- **WHEN** a maintainer inspects the repository for terminal configuration
- **THEN** WezTerm configuration is declared in a Home Manager module under `modules/home/` and imported from `modules/default.nix`

### Requirement: Simple settings are expressed as Nix attributes
Configuration values that do not require the WezTerm Lua API SHALL be declared in `programs.wezterm.settings` so they are rendered to Lua by Home Manager's configuration generator.

#### Scenario: Maintainer changes font size
- **WHEN** a maintainer updates a simple setting such as font_size or color_scheme
- **THEN** the value is declared as a Nix attribute in `programs.wezterm.settings`

### Requirement: Lua-dependent configuration is preserved in extraConfig
Configuration that requires the WezTerm Lua API, including plugin loading, event handlers, key bindings using `wezterm.action`, and tabline setup, SHALL be declared in `programs.wezterm.extraConfig` as Lua code.

#### Scenario: WezTerm loads plugins after migration
- **WHEN** WezTerm starts with the Home Manager-managed configuration
- **THEN** plugins such as resurrect, smart_workspace_switcher, tabline, and smart-splits are loaded via `wezterm.plugin.require` in the extraConfig Lua code

### Requirement: Dynamic color theme file remains the watched source
The custom `dank-theme` color scheme SHALL remain a dynamic TOML file at `~/.config/wezterm/colors/dank-theme.toml`, and the Home Manager-managed WezTerm Lua config SHALL reference and watch that same file instead of hardcoding theme colors in Nix.

#### Scenario: Theme generator updates dank-theme
- **WHEN** the dynamic `dank-theme.toml` file changes on disk
- **THEN** WezTerm watches and reloads that same file through the Home Manager-managed Lua config

### Requirement: Existing WezTerm behavior is preserved after migration
The migrated configuration SHALL produce the same effective WezTerm behavior as the existing Lua file, including fonts, key bindings, plugins, color scheme, SSH domains, and the toggle-opencode event handler.

#### Scenario: User presses the opencode toggle keybinding
- **WHEN** the user presses Ctrl+Shift+A in WezTerm after migration
- **THEN** the toggle-opencode event fires and opens or closes the opencode pane as before
