---
title: Canonical Spec Index
summary: 'Index of 10 active canonical specs defining capabilities for the nix-dotfiles repo: tmux, ssh-client, mutagen, snip-package, opencode-snip-integration, nvfetcher-package-sources, litellm-gateway, litellm-model-routing, litellm-client-integration, daemon-nix-config, system-manager-foundation'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.371Z'
updatedAt: '2026-07-15T21:17:57.371Z'
---
## Reason
Document openspec canonical spec index for nix config repo

## Raw Concept
**Task:**
Canonical spec index tracking all openspec capabilities in the nix-dotfiles repo

**Files:**
- openspec/specs/INDEX.md

**Flow:**
openspec change -> spec written -> archived to specs/ -> indexed in INDEX.md

**Timestamp:** 2026-07-15

## Narrative
### Structure
10 active specs organized under openspec/specs/. Each spec defines Purpose, Requirements, and Scenarios using RFC 2119 SHALL language.

### Highlights
All 10 specs are active. Source changes span: tmux-ssh-mutagen-modules (tmux, ssh-client, mutagen), migrate-tokf-to-snip (snip-package, opencode-snip-integration), add-system-manager (daemon-nix-config, system-manager-foundation), archive/2026-06-17-migrate-bifrost-to-litellm (litellm-gateway, litellm-model-routing, litellm-client-integration), archive/add-nvfetcher-for-packages (nvfetcher-package-sources)

### Rules
Specs are canonical — they represent the current truth after changes are archived. Each spec uses WHEN/THEN scenario format for behavioral requirements.
