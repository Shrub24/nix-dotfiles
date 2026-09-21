# ssh-client

## Purpose

Extends the ssh client capability so host aliases are generated from the fleet
registry with each machine's own login user, instead of a blanket user override
applied to a hand-maintained host list.

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

## ADDED Requirements

### Requirement: Host aliases carry each machine's registered login user

The SSH client module SHALL read each remote machine's login user from the fleet
registry as projected for the current evaluation
(`currentHost.peers.<name>.sshUser`), so machines owned by this repository and
build/admin machines can be reached with different accounts.

#### Scenario: Aliases carry the machine's own user

- **WHEN** the Home Manager ssh aspect is evaluated
- **THEN** each registered machine SHALL appear as its own `Host` block carrying
  that machine's `sshUser`
- **AND** a machine owned by this repository SHALL NOT inherit a build-server
  login user

#### Scenario: The current machine is not its own alias

- **WHEN** a host evaluation generates the alias blocks
- **THEN** the machine being evaluated SHALL NOT appear in its own alias list
- **AND** the exclusion SHALL be computed at the composition boundary rather
  than inside the ssh module
