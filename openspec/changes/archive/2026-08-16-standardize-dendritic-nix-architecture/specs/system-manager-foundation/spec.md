## ADDED Requirements

### Requirement: Host composition selects privilege-scoped aspects

The repository SHALL construct each supported host by explicitly selecting independently published user-scoped and system-scoped aspects.

#### Scenario: Arch host outputs are evaluated

- **WHEN** the flake evaluates the Arch host
- **THEN** its Home Manager output SHALL contain only selected user-scoped aspects
- **AND** its system-manager output SHALL contain only selected system-scoped aspects
- **AND** the two outputs SHALL preserve an explicit privilege boundary
