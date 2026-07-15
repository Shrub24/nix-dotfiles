---
title: LiteLLM Client Integration
summary: 'LiteLLM client integration: OpenCode provider config targets LiteLLM gateway with parity logical models, local AI clients (aichat, agentmemory) migrated declaratively, Bifrost-specific runtime wiring retired'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.277Z'
updatedAt: '2026-07-15T21:18:35.277Z'
---
## Reason
Document LiteLLM client integration spec

## Raw Concept
**Task:**
Migrate local AI clients from Bifrost to LiteLLM gateway declaratively

**Changes:**
- OpenCode provider config now targets LiteLLM gateway
- aichat and agentmemory migrated declaratively
- Bifrost-specific runtime wiring retired

**Files:**
- modules/home/opencode.nix

**Flow:**
Home Manager renders OpenCode provider overlay -> points to local LiteLLM gateway -> exposes parity logical models

**Timestamp:** 2026-07-15

**Author:** migrate-bifrost-to-litellm change

## Narrative
### Structure
Three requirements: (1) OpenCode provider config targets LiteLLM gateway with parity logical models, (2) Local AI clients (aichat, agentmemory) can be migrated declaratively, (3) Bifrost-specific runtime wiring retired after parity migration.

### Dependencies
LiteLLM gateway must be running. Uses LiteLLM-native downstream provider naming consistently.

### Highlights
OpenCode provider overlay points to local LiteLLM gateway endpoint. Exposes parity logical models. Uses LiteLLM-native downstream provider naming. Bifrost wiring fully retired once LiteLLM parity path is active.

### Rules
Rule 1: The system SHALL generate OpenCode provider configuration that targets the local LiteLLM gateway while preserving the current logical model contract
Rule 2: The system SHALL provide declarative host-level wiring so local AI clients (aichat, agentmemory) can be switched to LiteLLM without imperative local edits
Rule 3: The system SHALL retire Bifrost-specific generated provider/runtime wiring once the LiteLLM parity path is in place
