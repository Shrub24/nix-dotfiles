## Purpose

Defines how feature-owned Nix aspects are discovered, published, and explicitly composed into host outputs without crossing Home Manager and system privilege boundaries.

## ADDED Requirements

### Requirement: Features publish composable aspects

Each active feature SHALL publish its user-scoped and system-scoped configuration as separate composable aspects when it owns behavior in those scopes.

#### Scenario: Feature spans privilege boundaries

- **WHEN** a feature owns both user configuration and root-owned system behavior
- **THEN** each scope SHALL be independently selectable by host composition
- **AND** system-owned behavior SHALL NOT be implemented through the user-scoped aspect

### Requirement: Hosts explicitly select active aspects

Each host SHALL explicitly compose the feature aspects it uses rather than receiving every discovered module implicitly.

#### Scenario: Dormant feature file exists

- **WHEN** a feature module is present but its aspect is not selected by a host
- **THEN** that feature SHALL contribute no package, option, file, service, or activation behavior to the host

### Requirement: Automatic discovery is structurally safe

Automatic module discovery SHALL be limited to files that conform to the repository's flake-module contract.

#### Scenario: Discovery scans the module root

- **WHEN** the flake evaluates the automatic discovery tree
- **THEN** every discovered file SHALL be valid in that tree's module context
- **AND** raw Home Manager modules, raw system-manager modules, package functions, generated files, and disabled support files SHALL remain outside the scan scope

### Requirement: Host facts remain host-owned

Machine identity, architecture, home paths, and remote-machine data SHALL be declared by host composition and passed to selected aspects rather than hardcoded in reusable feature modules.

#### Scenario: Reusable aspect needs a host path or identity

- **WHEN** a feature aspect requires a host-specific fact
- **THEN** the host composition SHALL provide that fact from one canonical definition
- **AND** the aspect SHALL NOT duplicate the literal across feature modules
