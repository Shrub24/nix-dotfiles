---
children_hash: 25a922c33595d1eecb340639cc111af1e87497b3c4691f4ce28db8377c6c1260
compression_ratio: 0.9974424552429667
condensation_order: 0
covers: [opencode_snip_integration.md]
covers_token_total: 391
summary_level: d0
token_count: 390
type: summary
---
## opencode_snip_integration.md
---
title: OpenCode Snip Integration
summary: 'OpenCode-snip: registers opencode-snip plugin, relies on snip on PATH for shell command rewriting, preserves passthrough for unsupported commands'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.421Z'
updatedAt: '2026-07-15T21:17:57.421Z'
---
## Reason
Document OpenCode snip integration spec

## Raw Concept
**Task:**
Integrate snip command filtering into OpenCode via plugin

**Changes:**
- Registered opencode-snip plugin
- Configured snip-backed shell filtering

**Flow:**
OpenCode invokes shell command -> opencode-snip plugin -> snip rewrites supported commands, passes through unsupported

**Timestamp:** 2026-07-15

**Author:** migrate-tokf-to-snip change

## Narrative
### Structure
Three requirements: (1) OpenCode plugin registration for opencode-snip, (2) snip-backed shell filtering via PATH, (3) Unsupported commands passthrough preserving normal execution.

### Dependencies
Requires snip installed through Home Manager and available on PATH. Plugin config at apps/opencode/opencode.jsonc.

### Highlights
Plugin registered in managed OpenCode plugin list. snip prefixes supported commands. Unsupported/intentionally-bypassed commands continue normally without fallback changes.

### Rules
Rule 1: The system SHALL register opencode-snip in the managed OpenCode plugin list
Rule 2: The OpenCode integration SHALL rely on snip being available on PATH for shell command rewriting
Rule 3: The integration
[summary compaction; truncated from 391 tokens]