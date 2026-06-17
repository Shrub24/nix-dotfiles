<!--
canonical-spec: mutagen
status: active
source-change: tmux-ssh-mutagen-modules
source-spec: openspec/changes/tmux-ssh-mutagen-modules/specs/mutagen/spec.md
-->



## Purpose

Defines the canonical requirements for the mutagen capability.

## Requirements

### Requirement: Mutagen package install
The system SHALL install the `mutagen` package from nixpkgs.
The module SHALL be at `modules/home/remote/mutagen.nix`.
The module SHALL be a thin wrapper — package only, with room for future aliases/env.

#### Scenario: Module installs mutagen
- **WHEN** the remote module group is imported
- **THEN** `pkgs.mutagen` SHALL be available in the user's PATH

#### Scenario: Module is composable
- **WHEN** `modules/home/remote/` is evaluated
- **THEN** `mutagen.nix` SHALL be imported by `remote/default.nix`, and `remote/default.nix` SHALL be imported by `modules/default.nix`
