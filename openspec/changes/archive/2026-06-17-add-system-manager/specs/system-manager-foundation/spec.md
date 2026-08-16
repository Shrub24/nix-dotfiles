## ADDED Requirements

### Requirement: System configuration layer exists for non-NixOS hosts

The repository SHALL expose a declarative system-scoped configuration layer for supported non-NixOS hosts in addition to its existing Home Manager configuration.

#### Scenario: Flake exposes system-scoped host configuration

- **WHEN** a maintainer evaluates the flake outputs for the Arch host
- **THEN** the repository provides a system-scoped configuration entry for that host alongside the existing user-scoped Home Manager entry

### Requirement: System configuration structure is distinct from user configuration

The repository SHALL organize system-scoped modules and host entrypoints separately from user-scoped Home Manager modules so privilege boundaries are explicit.

#### Scenario: Maintainer locates system-owned configuration

- **WHEN** a maintainer needs to change daemon, root-owned, or machine-wide settings
- **THEN** the relevant configuration is located under a dedicated system-scoped host/module structure rather than mixed into Home Manager modules
