---
title: Nvfetcher Package Sources
summary: 'Nvfetcher package sources: committed metadata for snip, xberg-cli, headroom-ai; derivations consume generated metadata; excluded workflows (agentmemory, iii-engine, hermes-agent-src) unchanged; headroom-ai stays wheel-based'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.259Z'
updatedAt: '2026-07-15T21:18:35.259Z'
---
## Reason
Document nvfetcher package sources spec

## Raw Concept
**Task:**
Manage selected package sources through nvfetcher metadata instead of hardcoded fetch info

**Changes:**
- Added nvfetcher source metadata for snip, xberg-cli, headroom-ai
- Derivations now consume generated metadata
- Preserved wheel-based headroom-ai build

**Files:**
- pkgs/snip/
- pkgs/xberg-cli/
- pkgs/headroom-ai/

**Flow:**
nvfetcher generates metadata -> derivations read upstream version/source -> excluded workflows unchanged

**Timestamp:** 2026-07-15

**Author:** add-nvfetcher-for-packages change

## Narrative
### Structure
Four requirements: (1) Selected package sources managed through nvfetcher metadata, (2) Target derivations consume generated metadata (snip/kreuzberg full metadata, headroom-ai version-only), (3) Excluded workflows unchanged, (4) Headroom AI remains wheel-based.

### Dependencies
nvfetcher tooling for source updates. Selected package set: snip, xberg-cli, headroom-ai. Excluded: agentmemory, iii-engine, fish plugins, hermes-agent-src.

### Highlights
Headroom-ai preserves wheel-based build while adopting nvfetcher-managed version metadata. snip and xberg-cli consume full upstream version and source metadata. Purpose is TBD (created by archiving).

### Rules
Rule 1: The repository SHALL define committed nvfetcher source metadata for snip, xberg-cli, and headroom-ai
Rule 2: The snip and xberg-cli derivations SHALL consume externally generated source metadata for upstream version and source fetch information
Rule 3: The headroom-ai derivation SHALL consume externally generated version metadata while preserving its wheel-specific fetch construction
Rule 4: Existing excluded source workflows (agentmemory, iii-engine, fish plugins, hermes-agent-src) SHALL remain unchanged
