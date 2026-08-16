# repository-validation Specification

## Purpose
Defines one reproducible validation contract shared by developer commands, Git hooks, and continuous integration for Nix formatting, linting, and evaluation.

## Requirements

### Requirement: Repository formatting is declarative

The flake SHALL expose a tree-aware formatter and a formatting check for maintained repository files.

#### Scenario: Maintainer runs the flake formatter

- **WHEN** a maintainer runs `nix fmt`
- **THEN** the configured repository formatters SHALL process their declared file types
- **AND** generated, encrypted, or tool-state paths SHALL be excluded only when they are not maintained source

### Requirement: Flake checks cover formatting lint and evaluation

The flake check set SHALL enforce formatting, Statix, Deadnix, and evaluation of the supported Home Manager and system-manager configurations without mutating the lock file.

#### Scenario: Maintainer runs repository checks

- **WHEN** a maintainer runs the canonical flake check command
- **THEN** formatting or lint violations SHALL fail the command
- **AND** failure to evaluate either supported host configuration SHALL fail the command

### Requirement: Git hooks reuse canonical checks

Repository Git hooks SHALL invoke the same formatter, linter, and flake checks exposed by the repository rather than maintaining independent validation logic.

#### Scenario: Commit contains invalid maintained source

- **WHEN** a maintainer attempts to commit a staged file with a formatting or lint violation
- **THEN** the pre-commit hook SHALL reject the commit using the repository's canonical checks

#### Scenario: Branch fails flake validation

- **WHEN** a maintainer attempts to push a branch that fails the canonical flake check
- **THEN** the pre-push hook SHALL reject the push

### Requirement: Continuous integration matches local validation

Continuous integration SHALL run the canonical repository checks on proposed changes and SHALL keep workflow actions reproducibly pinned.

#### Scenario: Pull request is validated

- **WHEN** a pull request changes maintained repository content
- **THEN** CI SHALL run the same flake validation contract available locally
- **AND** workflow actions SHALL be pinned to immutable revisions managed by the repository's update automation
