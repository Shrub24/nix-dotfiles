## MODIFIED Requirements

### Requirement: System configuration structure is distinct from user configuration

The repository SHALL organize system-scoped modules and host entrypoints separately from user-scoped Home Manager modules so privilege boundaries are explicit.

#### Scenario: Maintainer locates system-owned configuration

- **WHEN** a maintainer needs to change daemon, root-owned, or machine-wide settings
- **THEN** the relevant configuration is located under a dedicated system-scoped host/module structure rather than mixed into Home Manager modules

### Requirement: Host composition uses typed topology, not an argument bus

Each supported host SHALL be composed from explicitly selected aspects, with shared service topology read from a typed top-level option rather than injected through `specialArgs`.

#### Scenario: Arch host is composed

- **WHEN** the flake constructs a host's Home Manager and system-manager outputs
- **THEN** cross-feature service topology SHALL come from `config.topology.*` populated at the host composition layer
- **AND** SHALL NOT be passed via `hostFacts`/`specialArgs`
- **AND** the two outputs SHALL preserve an explicit privilege boundary
