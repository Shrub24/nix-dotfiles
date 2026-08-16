<!--
delta: wezterm-config
-->

## MODIFIED Requirements

### Requirement: WezTerm configuration is managed declaratively through Home Manager

The repository SHALL manage WezTerm terminal configuration through a Home Manager module using `programs.wezterm` rather than a hand-maintained Lua file outside the flake.

#### Scenario: Maintainer reviews WezTerm configuration

- **WHEN** a maintainer inspects the repository for terminal configuration
- **THEN** WezTerm configuration is declared in `modules/shell/wezterm.nix`, published as `flake.modules.homeManager.wezterm`, and selected by the host aspect list
