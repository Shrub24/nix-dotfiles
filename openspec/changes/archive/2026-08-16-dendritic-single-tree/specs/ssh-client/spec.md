<!--
delta: ssh-client
-->

## MODIFIED Requirements

### Requirement: Declarative SSH client config

The system SHALL provide declarative SSH client configuration via `programs.ssh.*`.
The module SHALL be published as `flake.modules.homeManager.ssh` from `modules/ssh.nix` (which also holds the system-side `systemManager.ssh` value for the same feature).
The module SHALL NOT manage `known_hosts`, `authorized_keys`, or private key material.

#### Scenario: Module exists and enables SSH config

- **WHEN** `programs.ssh.enable = true` is set in the host config
- **THEN** `~/.ssh/config` SHALL be populated from the module's settings

#### Scenario: Module provides global client defaults

- **WHEN** `programs.ssh.settings` contains global options
- **THEN** those options SHALL appear in the generated `~/.ssh/config`

#### Scenario: Module leaves host-specific blocks to host config

- **WHEN** no host entries are defined in the module
- **THEN** the host config (`modules/hosts/arch/_home.nix`) MAY define Host blocks that appear in `~/.ssh/config`
