---
title: Architecture
summary: Dendritic architecture with 7 principles, module options pattern, sops-nix YAML-backed secrets, 4 systemd user services, and flake-parts entry point
tags: []
related: [nix_config/overview.md, nix_config/structure.md]
keywords: []
createdAt: '2026-07-15T21:05:11.008Z'
updatedAt: '2026-07-15T21:05:11.008Z'
---
## Reason
Curating from ARCHITECTURE.md — principles, data flow, key abstractions, module patterns, secrets, systemd services

## Raw Concept
**Task:**
Nix configuration architecture — dendritic home-manager with module options pattern

**Changes:**
- 7 architectural principles: pkgs/ for derivations, feature modules by concern, host compositions for identity
- Module options pattern: modules define options with mkOption, host configs set values
- YAML-backed sops-nix: centralized agents.yaml with template rendering at activation
- 4 systemd user services: Bifrost, Docs MCP, Hermes agent, Agentmemory

**Files:**
- ARCHITECTURE.md
- flake.nix
- modules/default.nix
- modules/home/sops.nix
- secrets/agents.yaml
- modules/home/agents/bifrost/default.nix
- modules/home/agents/docs-mcp.nix
- modules/home/agents/hermes.nix
- modules/home/agents/agentmemory.nix

**Flow:**
flake.nix (inputs + overlay) → hosts/arch/home.nix (identity + program enable) → modules/default.nix → feature modules → sops templates render at activation → systemd services start

**Timestamp:** 2026-07-15

**Author:** saurabhj

## Narrative
### Structure
Data flow: flake.nix is pure wiring (inputs, overlay, dev shell, homeConfigurations). modules/default.nix is single module entry point — imports all feature modules. hosts/arch/home.nix is sole host composition point — sets identity and enables programs. Modules expose options; host config sets values.

### Dependencies
Depends on flake-parts for modular composition. home-manager for user environment. sops-nix for secret decryption. system-manager for daemon layer. sops YAML placeholders render into: zsh-secrets.env, docs-mcp.env, bifrost-config.json, agentmemory.env at activation time.

### Highlights
Key abstractions: (1) Module Options Pattern — pi.nix defines programs.pi.* options, host sets provider/models/MCP/permissions. (2) Secret Management — centralized agents.yaml holds all API keys (github, google, openrouter, jina, tavily, brave, firecrawl, context7, openai, minimax, crofai, opencode), sops placeholders declared per key. (3) Systemd User Services — Bifrost MCP gateway (port 8765, bunx), Docs MCP (port 6280, bunx + OpenAI embeddings), Hermes gateway daemon, Agentmemory persistent memory (port 3111, viewer 3113). (4) Hermes + Agentmemory integration — hermes configured with @agentmemory/mcp MCP server and memory.provider="agentmemory".

### Rules
Rule 1: Derivations → pkgs/ — every custom build recipe lives under pkgs/, exposed via overlay.
Rule 2: Feature modules → modules/home/ — each file owns one concern, imported by modules/default.nix.
Rule 3: Dev-tools → modules/home/dev-tools/ — grouped concern for CLI/language tools.
Rule 4: Agent modules → modules/home/agents/ — composed via agents/default.nix.
Rule 5: Host compositions → hosts/<hostname>/home.nix — only place for host-specific identity and program enablement.
Rule 6: modules/default.nix is single module entry point.
Rule 7: flake.nix is pure wiring — no module logic.

### Examples
Pi agent flow: modules/home/agents/pi.nix defines programs.pi.* options → hosts/arch/home.nix sets provider, models, MCP servers, permissions → module renders config to ~/.pi/agent/. Secrets: secrets/agents.yaml holds all API keys → modules/home/sops.nix declares placeholders → templates render zsh-secrets.env, docs-mcp.env, bifrost-config.json, agentmemory.env at activation.
