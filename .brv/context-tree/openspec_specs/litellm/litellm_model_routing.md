---
title: LiteLLM Model Routing
summary: LiteLLM model routing preserving parity aliases (coder, main, summariser, budget, explorer, embedding) with primary/fallback deployments
tags: []
related: [openspec_specs/litellm/litellm_gateway.md, openspec_specs/litellm/litellm_client_integration.md]
keywords: []
createdAt: '2026-07-15T21:12:16.599Z'
updatedAt: '2026-07-15T21:12:16.599Z'
---
## Reason
Curate litellm-model-routing canonical spec

## Raw Concept
**Task:**
Migrate Bifrost model routing to LiteLLM with parity alias preservation

**Changes:**
- Preserved 6 logical model aliases: coder, main, summariser, budget, explorer, embedding
- Uses explicit LiteLLM provider semantics (e.g., openai/<model>) instead of Bifrost custom names

**Flow:**
Client request → logical alias → LiteLLM routing → primary deployment (or fallback)

**Timestamp:** 2026-06-17

## Narrative
### Structure
Routing config uses LiteLLM-native deployments with provider-qualified model definitions and explicit api_base/api_key.

### Highlights
Phase-1 migration uses built-in LiteLLM routing only — no custom Python routing hooks, Redis state, or quota-aware policy. Fallback ordering preserved from original Bifrost config.

### Rules
Rule 1: Logical aliases (coder, main, summariser, budget, explorer, embedding) MUST be preserved at parity
Rule 2: Deployments use explicit LiteLLM provider semantics — no custom provider names like "crof" or "opencode_go"
Rule 3: Phase-1 routing relies only on built-in LiteLLM routing and fallback features
Rule 4: Primary route failure triggers configured fallback deployment
