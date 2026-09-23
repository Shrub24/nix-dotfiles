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
The module SHALL be published as `flake.modules.homeManager.ssh` from `modules/ssh.nix` (which also holds the system-side `systemManager.ssh` and `nixos.ssh` values for the same feature).
The module SHALL NOT manage the user's `~/.ssh/known_hosts`, `authorized_keys`, or private key material.

#### Scenario: Module exists and enables SSH config

- **WHEN** `programs.ssh.enable = true` is set in the host config
- **THEN** `~/.ssh/config` SHALL be populated from the module's settings

#### Scenario: Module provides global client defaults

- **WHEN** `programs.ssh.settings` contains global options
- **THEN** those options SHALL appear in the generated `~/.ssh/config`

#### Scenario: Module leaves host-specific blocks to host config

- **WHEN** no host entries are defined in the module
- **THEN** the host config (`modules/hosts/legion/_home.nix`) MAY define Host blocks that appear in `~/.ssh/config`

### Requirement: Host aliases come from the fleet trust projection

The SSH client module SHALL render its host aliases from the fleet contract's
trust projection, reading each machine's reach account from the canonical
inventory (`fleet.hosts.<id>.ssh.user`) rather than restating it. The selection
of which hosts the machine talks to SHALL be made at the composition boundary,
because a class aspect cannot read the flake's `config.fleet`.

#### Scenario: Aliases carry the machine's own user

- **WHEN** the Home Manager ssh aspect is evaluated
- **THEN** each selected fleet host SHALL appear as its own `Host` block carrying
  that host's `ssh.user`
- **AND** a host with no `ssh.user` SHALL render without a `User` line rather
  than inheriting a build-server dispatch account

#### Scenario: The current machine is not its own alias

- **WHEN** a host composition builds the trust selection
- **THEN** the machine being evaluated SHALL NOT appear in its own selection
- **AND** the exclusion SHALL be computed at the composition boundary rather
  than inside the ssh module

### Requirement: Fleet host keys are pinned in the system known-hosts file

The system classes SHALL pin the host keys of every selected fleet host, ending
trust-on-first-use for those connections. NixOS SHALL use
`programs.ssh.knownHosts`; system-manager, which has no such option, SHALL render
the contract's `knownHosts` output into `/etc/ssh/ssh_known_hosts`. The user's
own `~/.ssh/known_hosts` SHALL remain unmanaged, because ssh appends to it.

#### Scenario: Selected hosts are pinned

- **WHEN** a system class is evaluated with a trust selection
- **THEN** every selected host with a bound key SHALL appear in the system
  known-hosts file
- **AND** a host whose key is not yet bound SHALL be omitted rather than
  rendering an incomplete entry

#### Scenario: The user file is left alone

- **WHEN** the ssh module is applied
- **THEN** `~/.ssh/known_hosts` SHALL NOT be created, modified, or managed

### Requirement: No secret management in module

The SSH module SHALL NOT manage private keys, authorized_keys, or the user's
known_hosts. These SHALL remain local state or be managed by other mechanisms
(e.g., sops-nix if needed).

#### Scenario: No user known_hosts manipulation

- **WHEN** the SSH module is applied
- **THEN** the user's `~/.ssh/known_hosts` SHALL NOT be created, modified, or
  managed by the module

#### Scenario: No authorized_keys manipulation

- **WHEN** the SSH module is applied
- **THEN** the `authorized_keys` file SHALL NOT be created, modified, or managed by the module

#### Scenario: No private key references outside user control

- **WHEN** the SSH module is applied
- **THEN** private keys SHALL NOT be created or stored by the module; IdentityFile paths MAY reference existing user-managed keys
