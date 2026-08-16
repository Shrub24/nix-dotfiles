## ADDED Requirements

### Requirement: Canonical specs declare lifecycle state

Each canonical spec SHALL declare whether it is active or superseded.

#### Scenario: Canonical spec is current

- **WHEN** a canonical spec describes the current delivered behavior
- **THEN** it is marked as active

#### Scenario: Canonical spec is replaced later

- **WHEN** a later change supersedes a canonical capability
- **THEN** the canonical spec records that it has been superseded instead of silently disappearing

### Requirement: Future changes reference canonical specs they alter

A change that modifies an existing capability SHALL reference the affected canonical spec rather than introducing a second competing source of truth.

#### Scenario: Proposal modifies existing behavior

- **WHEN** a future proposal changes an already-canonicalized capability
- **THEN** it treats that capability as a modified existing spec rather than a brand new capability
