# dendritic-module-composition Specification

## Purpose

Defines how feature-owned Nix aspects are discovered, published, and explicitly composed into host outputs without crossing Home Manager and system privilege boundaries.

## Requirements

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

### Requirement: Shared host and service data is typed and host-owned

Machine identity, architecture, home paths, and service topology SHALL be modeled as typed top-level options (`topology.hosts`, `topology.services`) or native Home Manager options (`home.username`, `home.homeDirectory`, `pkgs.stdenv.hostPlatform.system`), declared once at the host composition layer and read by consumers via the normal module system — never passed through `specialArgs` or duplicated in reusable feature modules.

#### Scenario: Reusable aspect needs a host path or identity

- **WHEN** a feature aspect requires a host-specific fact
- **THEN** the host composition SHALL declare that fact once in the typed topology option or as a native option value
- **AND** the aspect SHALL read it via the module system rather than an argument-passing bus
- **AND** the aspect SHALL NOT duplicate the literal across feature modules
