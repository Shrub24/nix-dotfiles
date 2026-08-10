## ADDED Requirements

### Requirement: Declarative tmux configuration
The system SHALL provide declarative tmux configuration via `programs.tmux.*`.
The module SHALL be at `modules/home/tmux.nix`.
The module SHALL be imported from `modules/default.nix`.

#### Scenario: Module exists and enables tmux
- **WHEN** `programs.tmux.enable = true` is set in the host config
- **THEN** the tmux binary SHALL be available, and `~/.config/tmux/tmux.conf` SHALL be populated from the module config

#### Scenario: Module sets sensible defaults
- **WHEN** tmux is enabled with a given `extraConfig`
- **THEN** the resulting tmux config SHALL include the extra directives and SHALL produce a working tmux session

#### Scenario: Module is imported from default.nix
- **WHEN** `modules/default.nix` is evaluated
- **THEN** `./home/tmux.nix` SHALL be in the imports list
