# canonical-spec-registry Specification

## Purpose
TBD - created by archiving change bootstrap-main-openspec-specs. Update Purpose after archive.

## Requirements

### Requirement: Canonical main specs exist for active completed capabilities

The repo SHALL maintain a populated `openspec/specs/` directory containing one canonical spec per active capability delivered by a completed change.

#### Scenario: Completed change capability is bootstrapped

- **WHEN** a completed change defines a capability whose delivered behavior is still active
- **THEN** `openspec/specs/<capability>/spec.md` exists for that capability

### Requirement: Canonical specs preserve provenance

Each canonical spec SHALL record the change and source spec from which it was bootstrapped.

#### Scenario: Maintainer inspects a canonical spec

- **WHEN** a maintainer reads a canonical spec file
- **THEN** the file identifies the source change and source spec path used to create it

### Requirement: The repo maintains a canonical spec index

The repo SHALL maintain an index of canonical specs that lists capability name, lifecycle status, and source change.

#### Scenario: Maintainer reviews canonical capabilities

- **WHEN** a maintainer opens the canonical spec index
- **THEN** they can see which canonical specs exist and which completed change introduced each one
