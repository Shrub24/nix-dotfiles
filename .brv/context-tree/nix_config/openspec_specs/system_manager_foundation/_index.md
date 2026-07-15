---
children_hash: 158b61d088ac54fe52543091513f5382870671486ad6e038af86fb3dea6ba8b4
compression_ratio: 0.9976359338061466
condensation_order: 0
covers: [system_manager_foundation.md]
covers_token_total: 423
summary_level: d0
token_count: 422
type: summary
---
## system_manager_foundation.md
---
title: System Manager Foundation
summary: 'System manager foundation: separate system-scoped config layer for non-NixOS hosts alongside Home Manager, with explicit privilege boundaries between system and user config'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.402Z'
updatedAt: '2026-07-15T21:17:57.402Z'
---
## Reason
Document system manager foundation spec

## Raw Concept
**Task:**
Establish declarative system-scoped configuration layer for non-NixOS hosts

**Changes:**
- Added system-scoped configuration layer
- Separated system and user module structures

**Files:**
- flake.nix (system-scoped outputs)

**Flow:**
maintainer evaluates flake -> system-scoped host entry available alongside user-scoped Home Manager entry

**Timestamp:** 2026-07-15

**Author:** add-system-manager change

## Narrative
### Structure
Two requirements: (1) System configuration layer exists for non-NixOS hosts, (2) System configuration structure is distinct from user configuration. Each with one scenario.

### Dependencies
Requires system-manager or equivalent system-scoped Nix tooling for non-NixOS hosts.

### Highlights
Explicit privilege boundaries: system-scoped modules and host entrypoints organized separately from user-scoped Home Manager modules. Daemon/root-owned settings go under dedicated system-scoped structure.

### Rules
Rule 1: The repository SHALL expose a declarative system-scoped configuration layer for supported non-NixOS hosts in addition to its existing Home Manager configuration
Rule 2: The repository SHALL organize system-scoped modules and host entrypoints sep
[summary compaction; truncated from 423 tokens]