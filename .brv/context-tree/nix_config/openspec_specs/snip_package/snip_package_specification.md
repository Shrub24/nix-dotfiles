---
title: Snip Package Specification
summary: 'Snip package: pinned derivation from github.com/edouard-claude/snip, exposed via agent tools bundle, replacing tokf in the active package set'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.415Z'
updatedAt: '2026-07-15T21:17:57.415Z'
---
## Reason
Document snip package spec replacing tokf

## Raw Concept
**Task:**
Replace tokf with snip package for shell command filtering

**Changes:**
- Added pinned snip derivation
- Exposed snip CLI through agent tools
- Removed tokf from active tooling

**Files:**
- pkgs/snip/
- modules/home/agents/

**Flow:**
programs.agentTools.enable=true -> snip in home.packages, tokf removed

**Timestamp:** 2026-07-15

**Author:** migrate-tokf-to-snip change

## Narrative
### Structure
Four requirements: (1) Pinned snip derivation from upstream release, (2) snip CLI exposure via agent tools bundle, (3) tokf removal from active tooling, (4) Direct CLI verification that snip binary is runnable.

### Dependencies
Upstream: github.com/edouard-claude/snip. Resolves from repo custom package overlay (not ambient system).

### Highlights
Pinned to explicit upstream release. Builds from repo overlay, not system install. tokf fully removed from agent tools package set.

### Rules
Rule 1: The system SHALL provide a custom snip derivation pinned to an explicit upstream release of github.com/edouard-claude/snip
Rule 2: The system SHALL expose the snip CLI through the Home Manager agent tools bundle
Rule 3: The system SHALL stop installing tokf as part of the active agent tools package set
Rule 4: The snip derivation SHALL expose a runnable snip binary
