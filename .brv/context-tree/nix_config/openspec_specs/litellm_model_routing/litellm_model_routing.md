---
title: LiteLLM Model Routing
summary: 'LiteLLM model routing: preserves 6 logical aliases (coder, main, summariser, budget, explorer, embedding) at parity, uses explicit provider-qualified model definitions, phase-1 routing uses built-in LiteLLM policy only'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.268Z'
updatedAt: '2026-07-15T21:18:35.268Z'
---
## Reason
Document LiteLLM model routing spec

## Raw Concept
**Task:**
Achieve parity model routing from Bifrost to LiteLLM using built-in LiteLLM features

**Changes:**
- Preserved 6 logical model aliases
- Used explicit provider-qualified model definitions
- No custom routing hooks, Redis, or quota-aware routing

**Files:**
- modules/home/agents/litellm/

**Flow:**
client requests alias -> LiteLLM routes to primary deployment -> falls back on failure

**Timestamp:** 2026-07-15

**Author:** migrate-bifrost-to-litellm change

## Narrative
### Structure
Four requirements: (1) Existing logical aliases preserved at parity (coder, main, summariser, budget, explorer, embedding), (2) Alias routing preserves primary targets and fallbacks with 2 scenarios, (3) Generated deployments use explicit provider semantics (e.g., openai/<model>), (4) Phase-1 routing uses built-in LiteLLM policy only.

### Dependencies
LiteLLM built-in routing and fallback features. No custom Python routing hooks, Redis-backed state, or quota-aware routing.

### Highlights
Uses explicit LiteLLM-compatible provider forms like openai/<model> with configured api_base and api_key. Must NOT depend on custom provider names like crof or opencode_go.

### Rules
Rule 1: The system SHALL preserve the current logical model aliases (coder, main, summariser, budget, explorer, embedding) during phase-1 migration
Rule 2: The system SHALL generate LiteLLM routing configuration that preserves the current provider/model intent and fallback ordering
Rule 3: The system SHALL generate LiteLLM deployments using provider-qualified model definitions (e.g., openai/<model>)
Rule 4: The generated config SHALL NOT depend on custom provider names like crof or opencode_go
Rule 5: Phase-1 routing SHALL rely only on built-in LiteLLM routing and fallback features
