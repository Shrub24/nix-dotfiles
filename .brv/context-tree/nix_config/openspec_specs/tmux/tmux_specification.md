---
title: Tmux Specification
summary: 'Tmux capability: declarative config via programs.tmux.* at modules/home/tmux.nix, imported from modules/default.nix, populating ~/.config/tmux/tmux.conf'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.376Z'
updatedAt: '2026-07-15T21:17:57.376Z'
---
## Reason
Document tmux declarative config spec

## Raw Concept
**Task:**
Declarative tmux configuration through Home Manager module

**Changes:**
- Added tmux module at modules/home/tmux.nix
- Imported from modules/default.nix

**Files:**
- modules/home/tmux.nix
- modules/default.nix

**Flow:**
programs.tmux.enable=true -> module generates ~/.config/tmux/tmux.conf

**Timestamp:** 2026-07-15

**Author:** tmux-ssh-mutagen-modules change

## Narrative
### Structure
Single-requirement spec: declarative tmux configuration via programs.tmux.* with 3 scenarios covering enablement, extraConfig defaults, and module import chain.

### Dependencies
Relies on Home Manager programs.tmux module. Imported through modules/default.nix.

### Highlights
Module at modules/home/tmux.nix. Populates ~/.config/tmux/tmux.conf. Supports extraConfig for user extensions.

### Rules
Rule 1: The system SHALL provide declarative tmux configuration via programs.tmux.*
Rule 2: The module SHALL be at modules/home/tmux.nix
Rule 3: The module SHALL be imported from modules/default.nix
