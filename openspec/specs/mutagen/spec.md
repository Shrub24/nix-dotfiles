<!--
canonical-spec: mutagen
status: active
source-change: archive/2026-08-09-tmux-ssh-mutagen-modules
source-spec: openspec/changes/archive/2026-08-09-tmux-ssh-mutagen-modules/specs/mutagen/spec.md
-->

## Purpose

Defines the canonical requirements for the mutagen capability.

## Requirements

### Requirement: Mutagen package install

The system SHALL install the `mutagen` package from nixpkgs.
The module SHALL be published as `flake.modules.homeManager.mutagen` from `modules/mutagen.nix`.
The module SHALL be a thin wrapper — package only, with room for future aliases/env.

#### Scenario: Module installs mutagen

- **WHEN** the `mutagen` aspect is selected by the host
- **THEN** `pkgs.mutagen` SHALL be available in the user's PATH

#### Scenario: Module is composable

- **WHEN** the host composition module is evaluated
- **THEN** the `mutagen` aspect SHALL be selectable independently of other remote features
