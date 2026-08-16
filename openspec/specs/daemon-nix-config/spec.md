<!--
canonical-spec: daemon-nix-config
status: active
source-change: archive/2026-06-17-add-system-manager
source-spec: openspec/changes/archive/2026-06-17-add-system-manager/specs/daemon-nix-config/spec.md
-->

## Purpose

Defines the canonical requirements for the daemon nix config capability.

## Requirements

### Requirement: Daemon-visible Nix policy is managed at system scope

Settings consumed by the Nix daemon, including daemon-level substituter policy and trusted keys, SHALL be declared in the system-scoped configuration layer rather than only in user-scoped Home Manager configuration.

#### Scenario: Nix daemon evaluates substituter configuration

- **WHEN** the Nix daemon performs an operation that requires substituter or trusted key policy
- **THEN** it uses configuration declared at system scope

### Requirement: nixbuild.net access is available to daemon-scoped execution

The system SHALL provide nixbuild.net access configuration and credentials in root-owned system scope so daemon-scoped Nix execution does not depend on Home Manager state or an interactive user shell.

#### Scenario: Daemon-scoped build uses nixbuild.net

- **WHEN** a daemon-scoped Nix operation needs to access `ssh-ng://eu.nixbuild.net`
- **THEN** the required access configuration and credential SHALL be available from system-managed state
- **AND** the credential SHALL NOT be stored in the Nix store or a user-managed path

#### Scenario: Nixbuild credential rotates

- **WHEN** system-scoped secret activation replaces the Nixbuild credential
- **THEN** `nix-daemon.service` SHALL be ordered after secret installation
- **AND** the daemon SHALL be restarted through declarative service integration

### Requirement: System secrets use a root-owned decryption identity

System-manager secrets SHALL be decrypted using a pre-generated root-owned age identity that is independent of the Home Manager user's identity.

#### Scenario: System secrets activate

- **WHEN** system-manager installs root-owned secrets
- **THEN** it SHALL use a persistent age identity readable only by root
- **AND** the encrypted secret recipients SHALL include that identity
