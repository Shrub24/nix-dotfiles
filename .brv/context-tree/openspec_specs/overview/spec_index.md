---
title: Spec Index
summary: Index of 10 active canonical specs across tmux, SSH, mutagen, snip, OpenCode, LiteLLM, system-manager, and nvfetcher domains
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:12:16.592Z'
updatedAt: '2026-07-15T21:12:16.592Z'
---
## Reason
Curate openspec canonical spec index from openspec/specs/INDEX.md

## Raw Concept
**Task:**
Maintain canonical specification index for the Nix dotfiles repository

**Changes:**
- Index tracks 10 active specs from 5 source changes
- nvfetcher-package-sources spec exists but status is TBD (purpose not yet defined)

**Files:**
- openspec/specs/INDEX.md

**Flow:**
spec defined → source change archived → canonical spec updated

**Timestamp:** 2026-07-15

## Narrative
### Structure
Table in INDEX.md maps capability name → status → source change → source spec path. All 10 listed specs have "active" status.

### Dependencies
Each spec references its originating openspec change under openspec/changes/

### Highlights
Specs originate from 5 source changes: add-system-manager, migrate-tokf-to-snip, tmux-ssh-mutagen-modules, archive/2026-06-17-migrate-bifrost-to-litellm, and archive/2026-06-19-add-nvfetcher-for-packages

### Rules
Rule 1: Each canonical spec is self-contained with Purpose, Requirements, and Scenarios
Rule 2: Source changes that produced specs are archived after merge
Rule 3: Spec status can be active, draft, or retired
