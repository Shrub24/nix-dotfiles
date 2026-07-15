---
title: Mutagen Specification
summary: 'Mutagen: thin wrapper module at modules/home/remote/mutagen.nix installing pkgs.mutagen from nixpkgs, composable via remote/default.nix import chain'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.264Z'
updatedAt: '2026-07-15T21:18:35.264Z'
---
## Reason
Document mutagen package spec

## Raw Concept
**Task:**
Install mutagen package for file synchronization

**Changes:**
- Added mutagen module at modules/home/remote/mutagen.nix

**Files:**
- modules/home/remote/mutagen.nix
- modules/home/remote/default.nix
- modules/default.nix

**Flow:**
remote module group imported -> pkgs.mutagen in PATH

**Timestamp:** 2026-07-15

**Author:** tmux-ssh-mutagen-modules change

## Narrative
### Structure
Single requirement: Mutagen package install with 2 scenarios. Thin wrapper — package only, with room for future aliases/env.

### Dependencies
Uses pkgs.mutagen from nixpkgs. Import chain: mutagen.nix -> remote/default.nix -> modules/default.nix.

### Highlights
Thin wrapper module with room for future aliases/environment variables. Composable through remote module group.

### Rules
Rule 1: The system SHALL install the mutagen package from nixpkgs
Rule 2: The module SHALL be at modules/home/remote/mutagen.nix
Rule 3: The module SHALL be a thin wrapper — package only, with room for future aliases/env
