<!--
delta: tmux
-->

## MODIFIED Requirements

### Requirement: Declarative tmux configuration

The system SHALL provide declarative tmux configuration via `programs.tmux.*`.
The module SHALL be published as `flake.modules.homeManager.tmux` from `modules/shell/tmux.nix` and selected by the host aspect list.

#### Scenario: Module exists and enables tmux

- **WHEN** `programs.tmux.enable = true` is set in the host config
- **THEN** the tmux binary SHALL be available, and `~/.config/tmux/tmux.conf` SHALL be populated from the module config

#### Scenario: Module sets sensible defaults

- **WHEN** tmux is enabled with a given `extraConfig`
- **THEN** the resulting tmux config SHALL include the extra directives and SHALL produce a working tmux session

#### Scenario: Module is imported from default.nix

- **WHEN** the host composition module (`modules/hosts/arch.nix`) is evaluated
- **THEN** the `tmux` aspect SHALL be in the homeManager selection list (replacing the former `modules/default.nix` import chain)
