## Purpose

Defines how a fresh NixOS and Home Manager switch creates required mutable
filesystem state without relying on leftovers from an earlier installation.

## ADDED Requirements

### Requirement: Filesystem state has one feature-local owner

Each required filesystem path SHALL be declared by the feature that consumes
it at the privilege scope that owns it. Home Manager SHALL own user files and
mutable user paths; NixOS SHALL own mutable system paths only when no native
module already owns them.

#### Scenario: Fresh user activation

- **WHEN** Home Manager activates for a new user with an empty home directory
- **THEN** every configured user file or directory required before first use SHALL exist with user ownership
- **AND** no root-scoped rule SHALL create user home state

#### Scenario: Native NixOS service owns its state

- **WHEN** a native NixOS module creates a service's mutable state directory
- **THEN** no duplicate repository tmpfiles rule SHALL claim that directory

### Requirement: Mutable seed files preserve runtime ownership

A feature that requires an initial mutable file SHALL provide a declarative
seed that is copied only when the destination is absent. Later runtime changes
to that file SHALL survive subsequent switches.

#### Scenario: Seed destination is absent

- **WHEN** the user tmpfiles rules run and a required mutable seed file does not exist
- **THEN** the configured seed SHALL be copied into the user-owned destination

#### Scenario: Seed destination was changed at runtime

- **WHEN** the user tmpfiles rules run and the destination already exists
- **THEN** the existing file SHALL remain unchanged

### Requirement: Logind owns user runtime directories

The configuration SHALL NOT create `/run/user/<uid>` through root tmpfiles.
User runtime directories SHALL remain owned by logind and user-session
lifecycle.

#### Scenario: System boots before user login

- **WHEN** the system reaches its normal boot target without a user session
- **THEN** repository tmpfiles rules SHALL NOT synthesize a user runtime directory

### Requirement: Desktop bootstrap is evaluation-verifiable

Repository checks SHALL evaluate the Home Manager activation and expose the
generated user tmpfiles declarations for the required mutable paths.

#### Scenario: Fresh configuration evaluation

- **WHEN** the primary user's Home Manager configuration is evaluated
- **THEN** the generated user tmpfiles rules SHALL contain the required paths, modes and seed sources
- **AND** no competing root-scoped rule SHALL claim those user paths
