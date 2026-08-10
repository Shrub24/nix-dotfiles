## Purpose

Provide the Surge download-manager TUI and CLI as a reproducible user tool without implicitly exposing its network server.

## ADDED Requirements

### Requirement: Surge is installed at the pinned release
The user environment SHALL provide Surge release 0.11.2 and `surge --version` SHALL report 0.11.2.

#### Scenario: Version verification
- **WHEN** the user runs `surge --version`
- **THEN** the command reports version 0.11.2

### Requirement: Surge server is opt-in
The configuration SHALL NOT start the Surge server or install its service automatically.

#### Scenario: Home Manager activation
- **WHEN** Home Manager activates the configuration
- **THEN** no Surge service is enabled and no Surge listening port is created by the configuration
