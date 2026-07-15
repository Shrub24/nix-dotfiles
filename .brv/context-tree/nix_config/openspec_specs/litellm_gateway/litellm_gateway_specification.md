---
title: LiteLLM Gateway Specification
summary: 'LiteLLM gateway: Home Manager-managed user service with sops-managed secrets, auto-restart on config changes, OpenAI-compatible endpoint, optional global Headroom ASGI middleware support'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.272Z'
updatedAt: '2026-07-15T21:18:35.272Z'
---
## Reason
Document LiteLLM gateway spec

## Raw Concept
**Task:**
Provide declaratively managed LiteLLM gateway service via Home Manager

**Changes:**
- Home Manager-managed LiteLLM user service
- sops-managed runtime secrets
- Auto-restart on config changes
- Optional Headroom ASGI middleware

**Files:**
- modules/home/agents/litellm/
- modules/home/sops.nix

**Flow:**
programs.litellm.enable=true -> service reads sops secrets + rendered config -> serves OpenAI-compatible endpoint -> restarts on config change

**Timestamp:** 2026-07-15

**Author:** migrate-bifrost-to-litellm change

## Narrative
### Structure
Four requirements: (1) LiteLLM gateway service declaratively managed with sops secrets, (2) Gateway parity preserves local access contract (OpenAI-compatible endpoint), (3) Configuration changes trigger managed restarts, (4) Optional global Headroom ASGI middleware support via CompressionMiddleware.

### Dependencies
sops-nix for runtime secrets. Home Manager user service management. Optional: Headroom ASGI middleware (headroom.integrations.asgi.CompressionMiddleware).

### Highlights
Service auto-starts for user. Reads API keys from generated env file. Consumes generated LiteLLM config file. Both under user config directory. Optional Headroom middleware: mounts CompressionMiddleware through a wrapper.

### Rules
Rule 1: The system SHALL provide a Home Manager-managed LiteLLM gateway service that starts automatically, reads runtime secrets from a sops-managed environment file, and renders static proxy configuration from repo-managed Nix configuration
Rule 2: The system SHALL expose LiteLLM through the existing local gateway role so local tools can access an OpenAI-compatible endpoint
Rule 3: The system SHALL restart the LiteLLM user service when generated gateway configuration or rendered runtime secret files change
Rule 4: The system SHALL support optional global Headroom ASGI middleware enablement
