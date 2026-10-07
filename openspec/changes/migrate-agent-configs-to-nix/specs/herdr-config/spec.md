## Purpose

Owns Herdr's declarative user configuration: the native Home Manager module
renders the application's `config.toml`, and the repository declares the
symlink-free state layout. Plugin installation, plugin state, and all other
Herdr runtime files remain Herdr-owned.

## ADDED Requirements

### Requirement: Herdr is enabled through the native Home Manager module

The system SHALL enable Herdr through the native Home Manager
`programs.herdr` module with its package supplied by `inputs.llm-agents`.
A host that uses Herdr SHALL select the `herdr` Home Manager aspect. No
NixOS aspect SHALL be introduced for Herdr.

#### Scenario: Host composition enables Herdr

- **WHEN** `hmAspects` in `modules/hosts/legion.nix` and `_home.nix` in the host directory are inspected
- **THEN** the `herdr` aspect is selected and `programs.herdr.enable = true` is set
- **AND** the Herdr package resolves from `inputs.llm-agents`

### Requirement: Herdr configuration file is seeded from Nix

The system SHALL render Herdr's `config.toml` from `programs.herdr.settings`
and seed it at activation as a real writable file at
`$XDG_CONFIG_HOME/herdr/config.toml`. The path SHALL NOT be a store symlink,
because Herdr and its plugin persist settings by writing a temporary file and
renaming it over the path, which a store symlink cannot serve. The activation
SHALL replace the file with the declared settings, so every switch re-seeds
the declared keys; the plugin's own blocks SHALL be re-applied after the seed.
The live `~/.config/herdr` directory SHALL hold no checked-in configuration
after migration.

#### Scenario: Configuration is seeded at activation

- **WHEN** the Home Manager configuration is applied with Herdr enabled
- **THEN** `~/.config/herdr/config.toml` is a real writable file whose
  declared keys match the user's declarative settings
- **AND** `~/.config/herdr` is a real directory, not a symlink

#### Scenario: Herdr's own writes do not displace the declaration

- **WHEN** Herdr persists a setting through its UI and the host switches again
- **THEN** the declared keys are re-seeded and the file is still a real file
- **AND** the plugin's blocks are re-applied after the seed

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
