<!--
canonical-spec: ssh-client
status: active
source-change: archive/2026-08-09-tmux-ssh-mutagen-modules
source-spec: openspec/changes/archive/2026-08-09-tmux-ssh-mutagen-modules/specs/ssh-client/spec.md
-->

## Purpose

Defines the canonical requirements for the ssh client capability.

## Requirements

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

### Requirement: No secret management in module

The SSH module SHALL NOT manage private keys, authorized_keys, or known_hosts.
These SHALL remain local state or be managed by other mechanisms (e.g., sops-nix if needed).

#### Scenario: No known_hosts manipulation

- **WHEN** the SSH module is applied
- **THEN** the `known_hosts` file SHALL NOT be created, modified, or managed by the module

#### Scenario: No authorized_keys manipulation

- **WHEN** the SSH module is applied
- **THEN** the `authorized_keys` file SHALL NOT be created, modified, or managed by the module

#### Scenario: No private key references outside user control

- **WHEN** the SSH module is applied
- **THEN** private keys SHALL NOT be created or stored by the module; IdentityFile paths MAY reference existing user-managed keys
