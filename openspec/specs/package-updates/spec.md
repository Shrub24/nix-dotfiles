# package-updates Specification

## Purpose

How this repository declares the upstream pins of the packages it owns, updates
them through the fleet package-update contract, and accepts the result: one
registered owner per pin set, each pin declared with the package that consumes
it, and acceptance through the canonical validation.

## Requirements

### Requirement: The repository registers the package families it owns

Every package family whose upstream revision this repository pins SHALL be
registered with the fleet package-update contract, and each registered name
SHALL resolve to a package output of that name. No pinned family SHALL be left
unregistered.

#### Scenario: An owned package family is updated

- **WHEN** the update app runs without a package argument
- **THEN** every family this repository owns is updated in turn

#### Scenario: A pinned family is not registered

- **WHEN** a package consumes a pin that no registered owner covers
- **THEN** that family is not updatable, and the omission is a defect rather than a supported state

### Requirement: One owner per pin set

A set of pins that must move together SHALL have exactly one registered owner.
An output derived from an owner's pin SHALL NOT be registered separately, and a
shared pin SHALL NOT be written by two owners.

#### Scenario: A release whose artifacts are keyed to each other

- **WHEN** a release is updated whose archive, runtime asset and dependency hash are keyed to the same tag
- **THEN** all of them move in one owner's step

#### Scenario: A derived output

- **WHEN** a package builds from an already-registered owner's pin
- **THEN** it is not registered and is not updated on its own

### Requirement: Pins are declared with the package that owns them

Each package's upstream pin SHALL be declared in that package's own source file
as a literal version and source, and no package SHALL read its pin from a shared
generated file.

#### Scenario: An update rewrites a pin

- **WHEN** an owner updates its pin
- **THEN** the change appears in that package's own file
- **AND** no shared generated source file is rewritten

### Requirement: Update tooling resolves from this repository's pins

The update app and everything an update invokes SHALL resolve from this
repository's evaluated package set. No update path SHALL fetch tooling from a
floating channel.

#### Scenario: The update app starts

- **WHEN** the update app runs
- **THEN** the tool it runs is the revision this repository pins
- **AND** no floating package reference is resolved

### Requirement: Updates are accepted only after the canonical validation

An update SHALL be accepted only once the repository's canonical validation
passes on the updated revision: formatting, the flake checks, and both NixOS
host configurations evaluating. A failed update SHALL be left uncommitted for
review rather than committed or reverted automatically.

#### Scenario: An update changes a package's content

- **WHEN** an owner's update completes
- **THEN** the canonical validation runs before the change is kept

#### Scenario: An update breaks evaluation

- **WHEN** the updated revision fails the canonical validation
- **THEN** the working change stays in place for review and is not committed

### Requirement: Updates are reproducible against a recorded target

Each owner's update SHALL accept a recorded target revision, so that an
acceptance run is deterministic and a second run at the same target produces no
change.

#### Scenario: Repeating an acceptance run

- **WHEN** an owner is updated at a target that has already been applied
- **THEN** the second run produces no diff

### Requirement: One mechanism updates package pins

The repository SHALL have exactly one mechanism for updating package pins. A
second mechanism SHALL NOT be added alongside the registered owners.

#### Scenario: A new pin is introduced

- **WHEN** a package gains an upstream pin
- **THEN** it is registered with the existing mechanism rather than given its own update path
