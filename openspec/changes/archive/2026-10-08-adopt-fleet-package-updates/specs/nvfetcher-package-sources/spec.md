# Spec Delta

## REMOVED Requirements

### Requirement: Selected package sources are managed through nvfetcher metadata

**Reason**: The repository no longer carries nvfetcher metadata. Pins are declared by the package that owns them, so there is no separate source-update configuration to keep in step with the active package set.

**Migration**: Each source nvfetcher managed is declared as a literal version and source in its own package file, and its package family is registered with the package-update contract (`package-updates`).

### Requirement: Target derivations consume generated nvfetcher metadata

**Reason**: A generated source set cannot be located and rewritten by the update tooling, which is what forced the dependency hash to be refreshed by hand and left pins in a file no package owns.

**Migration**: A package's version and source are literals in its own file, and an update rewrites that file; a coupled pin set is refreshed by its single owner's update step.

## ADDED Requirements

### Requirement: nvfetcher is retired

This capability is superseded. The repository no longer carries nvfetcher configuration, a generated source set, or an nvfetcher update app; every package pin is declared by the package that owns it and updated through the package-update contract. While the capability remains superseded, the repository SHALL NOT add nvfetcher metadata, a generated source set, or a second pin-update path.

#### Scenario: Repository is inspected after the transition

- **WHEN** the package layer is inspected after the transition
- **THEN** no nvfetcher configuration, generated source set or nvfetcher update app exists
