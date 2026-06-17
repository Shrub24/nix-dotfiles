<!--
canonical-spec: daemon-nix-config
status: active
source-change: add-system-manager
source-spec: openspec/changes/add-system-manager/specs/daemon-nix-config/spec.md
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
The system SHALL provide nixbuild.net access configuration in a way that is visible to daemon-scoped or root-scoped Nix execution without depending on an interactive user shell session.

#### Scenario: Daemon-scoped build uses nixbuild.net
- **WHEN** a daemon-scoped Nix operation needs to access `ssh-ng://eu.nixbuild.net`
- **THEN** the required access configuration is available to that execution path without relying on user-only shell environment inheritance
