## Purpose

Owns Herdr's declarative user configuration: the native Home Manager module
renders the application's `config.toml`, and the repository declares the
symlink-free state layout. Plugin installation, plugin state, and all other
Herdr runtime files remain Herdr-owned.

## ADDED Requirements

### Requirement: Herdr is enabled through the native Home Manager module

The system SHALL enable Herdr through the native Home Manager
`programs.herdr` module with its package supplied by `inputs.llm-agents`.
The Arch host SHALL select the `herdr` Home Manager aspect. No
system-manager or NixOS aspect SHALL be introduced for Herdr.

#### Scenario: Host composition enables Herdr

- **WHEN** `hmAspects` in `modules/hosts/legion.nix` and `_home.nix` in the host directory are inspected
- **THEN** the `herdr` aspect is selected and `programs.herdr.enable = true` is set
- **AND** the Herdr package resolves from `inputs.llm-agents`

### Requirement: Herdr configuration file is rendered by Nix

The system SHALL render Herdr's `config.toml` from `programs.herdr.settings`
as a read-only Nix store path at `$XDG_CONFIG_HOME/herdr/config.toml`. The
Herdr configuration directory SHALL NOT be a symlink into the repository
working tree. The live `~/.config/herdr` directory SHALL hold no checked-in
configuration after migration.

#### Scenario: Rendered configuration resolves to the store

- **WHEN** the Home Manager configuration is applied with Herdr enabled
- **THEN** `~/.config/herdr/config.toml` resolves to a read-only Nix store path
- **AND** its content matches the user's declarative settings
- **AND** `~/.config/herdr` is a real directory, not a symlink

### Requirement: Herdr runtime state is not Nix-owned

Herdr runtime state SHALL remain outside the store and SHALL NOT be managed
by Nix. This covers the plugin registry, plugin checkouts, session state,
logs, sockets, the release notes cache, and the plugin lock file.

#### Scenario: Herdr can still manage its plugins

- **WHEN** Herdr installs, enables, or updates a plugin
- **THEN** the plugin registry and plugin checkouts are updated under `~/.config/herdr`
- **AND** no Home Manager option owns those paths

#### Scenario: Herdr keeps its session state

- **WHEN** Herdr records session state, logs, or its plugin lock
- **THEN** the writes succeed into non-store paths under `~/.config/herdr`
- **AND** no Nix expression references them as a source
