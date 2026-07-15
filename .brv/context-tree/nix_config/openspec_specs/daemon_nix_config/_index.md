---
children_hash: 9daac65dab89256166edcd7e995276610b443a17122bc537c18e7c494ba6f772
compression_ratio: 0.9978260869565218
condensation_order: 0
covers: [daemon_nix_config.md]
covers_token_total: 460
summary_level: d0
token_count: 459
type: summary
---
## daemon_nix_config.md
---
title: Daemon Nix Config
summary: 'Daemon nix config: daemon-visible Nix policy (substituters, trusted keys) at system scope, nixbuild.net access available to daemon-scoped execution without user shell dependency'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.282Z'
updatedAt: '2026-07-15T21:18:35.282Z'
---
## Reason
Document daemon nix config spec

## Raw Concept
**Task:**
Ensure Nix daemon can access required configuration (substituters, nixbuild.net) at system scope

**Changes:**
- Moved daemon-visible Nix policy to system scope
- Ensured nixbuild.net access for daemon-scoped execution

**Files:**
- flake.nix (system-scoped config)

**Flow:**
Nix daemon operation -> reads system-scoped substituter/trusted key policy -> accesses nixbuild.net without user shell

**Timestamp:** 2026-07-15

**Author:** add-system-manager change

## Narrative
### Structure
Two requirements: (1) Daemon-visible Nix policy (substituter policy, trusted keys) managed at system scope rather than only user-scoped Home Manager, (2) nixbuild.net access available to daemon-scoped execution without depending on interactive user shell.

### Dependencies
System-scoped configuration layer. nixbuild.net access via ssh-ng://eu.nixbuild.net.

### Highlights
Substituter policy and trusted keys declared at system scope so Nix daemon can evaluate them. nixbuild.net access works for daemon-scoped/root-scoped Nix execution without user shell environment inheritance.

### Rules
Rule 1: Settings consumed by the Nix daemon, including daemon-level substituter policy and trusted keys, SHALL be declared in the system-scoped configuration layer
Rule 2: The system SHALL provide nixbuild.net access configuration in a way that is visible to daemon-scoped or root-
[summary compaction; truncated from 460 tokens]