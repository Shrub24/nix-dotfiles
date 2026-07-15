---
title: LiteLLM Gateway
summary: LiteLLM gateway as a Home Manager-managed user service with declarative config, sops secrets, and optional Headroom ASGI middleware
tags: []
related: [openspec_specs/litellm/litellm_model_routing.md, openspec_specs/litellm/litellm_client_integration.md]
keywords: []
createdAt: '2026-07-15T21:12:16.597Z'
updatedAt: '2026-07-15T21:12:16.597Z'
---
## Reason
Curate litellm-gateway canonical spec

## Raw Concept
**Task:**
Provide declaratively managed LiteLLM gateway service for local AI clients

**Changes:**
- Migrated from Bifrost gateway to LiteLLM
- Added optional global Headroom ASGI middleware support

**Files:**
- modules/home/agents/litellm/
- openspec/specs/litellm-gateway/spec.md

**Flow:**
Home Manager enable → render config + env file → start user service → serve OpenAI-compatible endpoint

**Timestamp:** 2026-06-17

## Narrative
### Structure
Gateway service managed via `programs.litellm.enable`. Renders config and sops-managed env file to user config dir. Restarts on config changes.

### Dependencies
Requires sops-nix for API key secrets, Home Manager for service management

### Highlights
OpenAI-compatible proxy endpoint. Supports `headroom.integrations.asgi.CompressionMiddleware` when global Headroom is enabled. Service auto-restarts on config/env changes.

### Rules
Rule 1: LiteLLM service reads runtime API keys from generated environment file
Rule 2: Gateway config changes trigger managed service restarts
Rule 3: Headroom middleware is optional and only mounted when explicitly enabled
