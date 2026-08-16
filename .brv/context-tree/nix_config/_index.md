---
children_hash: 4f09832d69298b63f251c4c731f2fffcdb13fade3b4edcecf9785d307bc95ebf
compression_ratio: 0.9998892212252133
condensation_order: 2
covers: [architecture/_index.md, openspec_specs/_index.md, overview/_index.md, structure/_index.md]
covers_token_total: 9027
summary_level: d2
token_count: 9026
type: summary
---
## architecture/_index.md
---
children_hash: 3977207cb036f817a8ed01462739c89b19d805acf60b73aca1d05387386f4253
compression_ratio: 0.9989316239316239
condensation_order: 1
covers: [architecture.md]
covers_token_total: 936
summary_level: d1
token_count: 935
type: summary
---
## architecture.md
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
Pi agent flow: modules/home/agents/pi.nix defines programs.pi.* options → hosts/arch/home.nix sets provider, models, MCP servers, permissions → module renders config to ~/.pi/agent/. Secrets: secrets/agents.yaml holds all API keys → modules/home/sops.nix declares placeholders → templates render zsh-secrets.en
[summary compaction; truncated from 936 tokens]

## openspec_specs/_index.md
---
children_hash: 4086191a09afa10523bd8a015f2d1a46edfac3d68c84ca2bd585e4114fe89462
compression_ratio: 0.9998348745046235
condensation_order: 1
covers: [canonical_spec_index.md, daemon_nix_config/_index.md, litellm_client_integration/_index.md, litellm_gateway/_index.md, litellm_model_routing/_index.md, mutagen/_index.md, nvfetcher_package_sources/_index.md, opencode_snip_integration/_index.md, snip_package/_index.md, ssh_client/_index.md, system_manager_foundation/_index.md, tmux/_index.md]
covers_token_total: 6056
summary_level: d1
token_count: 6055
type: summary
---
## canonical_spec_index.md
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


## daemon_nix_config/_index.md
---
children_hash: 9daac65dab89256166edcd7e995276610b443a17122bc537c18e7c494ba6f772
compression_ratio: 0.9978260869565218
condensation_order: 0
covers: [daemon_nix_config.md]
covers_token_total: 460
summary_level: d0
token_count: 459
type: summary
---
## daemon_nix_config.md
---
title: Daemon Nix Config
summary: 'Daemon nix config: daemon-visible Nix policy (substituters, trusted keys) at system scope, nixbuild.net access available to daemon-scoped execution without user shell dependency'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.282Z'
updatedAt: '2026-07-15T21:18:35.282Z'
---
## Reason
Document daemon nix config spec

## Raw Concept
**Task:**
Ensure Nix daemon can access required configuration (substituters, nixbuild.net) at system scope

**Changes:**
- Moved daemon-visible Nix policy to system scope
- Ensured nixbuild.net access for daemon-scoped execution

**Files:**
- flake.nix (system-scoped config)

**Flow:**
Nix daemon operation -> reads system-scoped substituter/trusted key policy -> accesses nixbuild.net without user shell

**Timestamp:** 2026-07-15

**Author:** add-system-manager change

## Narrative
### Structure
Two requirements: (1) Daemon-visible Nix policy (substituter policy, trusted keys) managed at system scope rather than only user-scoped Home Manager, (2) nixbuild.net access available to daemon-scoped execution without depending on interactive user shell.

### Dependencies
System-scoped configuration layer. nixbuild.net access via ssh-ng://eu.nixbuild.net.

### Highlights
Substituter policy and trusted keys declared at system scope so Nix daemon can evaluate them. nixbuild.net access works for daemon-scoped/root-scoped Nix execution without user shell environment inheritance.

### Rules
Rule 1: Settings consumed by the Nix daemon, including daemon-level substituter policy and trusted keys, SHALL be declared in the system-scoped configuration layer
Rule 2: The system SHALL provide nixbuild.net access configuration in a way that is visible to daemon-scoped or root-
[summary compaction; truncated from 460 tokens]

## litellm_client_integration/_index.md
---
children_hash: 98af852b710b3a9ddf176f2bb26f488823ab14ccaf9540b4a5010afb23c63cfa
compression_ratio: 0.9979838709677419
condensation_order: 0
covers: [litellm_client_integration.md]
covers_token_total: 496
summary_level: d0
token_count: 495
type: summary
---
## litellm_client_integration.md
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
Rule 3: The system SHALL retire Bifrost-
[summary compaction; truncated from 496 tokens]

## litellm_gateway/_index.md
---
children_hash: f81f0408c1acf0ff3657c6fd0ae7008b73afae4dc62f8399281cac516cdee9c1
compression_ratio: 0.9982547993019197
condensation_order: 0
covers: [litellm_gateway_specification.md]
covers_token_total: 573
summary_level: d0
token_count: 572
type: summary
---
## litellm_gateway_specification.md
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
Rule 3: The system SHALL restart the LiteLLM user service when generated gateway configuration or rendered runtime secret files chang
[summary compaction; truncated from 573 tokens]

## litellm_model_routing/_index.md
---
children_hash: 9039e813862f7b20e69824cb2cb4422d4831409051016b331e8709c5952146f6
compression_ratio: 0.9981851179673321
condensation_order: 0
covers: [litellm_model_routing.md]
covers_token_total: 551
summary_level: d0
token_count: 550
type: summary
---
## litellm_model_routing.md
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
Rule 5: Ph
[summary compaction; truncated from 551 tokens]

## mutagen/_index.md
---
children_hash: 4d730d0c75c710fb6acd606ea90616c483f1c0bde70d3109b770359970c58b42
compression_ratio: 0.9970760233918129
condensation_order: 0
covers: [mutagen_specification.md]
covers_token_total: 342
summary_level: d0
token_count: 341
type: summary
---
## mutagen_specification.md
---
title: Mutagen Specification
summary: 'Mutagen: thin wrapper module at modules/home/remote/mutagen.nix installing pkgs.mutagen from nixpkgs, composable via remote/default.nix import chain'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:18:35.264Z'
updatedAt: '2026-07-15T21:18:35.264Z'
---
## Reason
Document mutagen package spec

## Raw Concept
**Task:**
Install mutagen package for file synchronization

**Changes:**
- Added mutagen module at modules/home/remote/mutagen.nix

**Files:**
- modules/home/remote/mutagen.nix
- modules/home/remote/default.nix
- modules/default.nix

**Flow:**
remote module group imported -> pkgs.mutagen in PATH

**Timestamp:** 2026-07-15

**Author:** tmux-ssh-mutagen-modules change

## Narrative
### Structure
Single requirement: Mutagen package install with 2 scenarios. Thin wrapper — package only, with room for future aliases/env.

### Dependencies
Uses pkgs.mutagen from nixpkgs. Import chain: mutagen.nix -> remote/default.nix -> modules/default.nix.

### Highlights
Thin wrapper module with room for future aliases/environment variables. Composable through remote module group.

### Rules
Rule 1: The system SHALL install the mutagen package from nixpkgs
Rule 2: The module SHALL be at modules/home/remote/mutagen.nix
Rule 3: The mo
[summary compaction; truncated from 342 tokens]

## nvfetcher_package_sources/_index.md
---
children_hash: 19b166eb5dcf533ef95766bcc987700a78d5bf7a2073d6b86e2c5b8ccd2adbfb
compression_ratio: 0.9981949458483754
condensation_order: 0
covers: [nvfetcher_package_sources.md]
covers_token_total: 554
summary_level: d0
token_count: 553
type: summary
---
## nvfetcher_package_sources.md
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
Rule 4: Existing excluded source workflows
[summary compaction; truncated from 554 tokens]

## opencode_snip_integration/_index.md
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

## snip_package/_index.md
---
children_hash: 69b8e9834e26b85068502930ec6c9b2b029470fa3dc8510a0bebd7556f9c5db4
compression_ratio: 0.9975845410628019
condensation_order: 0
covers: [snip_package_specification.md]
covers_token_total: 414
summary_level: d0
token_count: 413
type: summary
---
## snip_package_specification.md
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
Rule 3: The system SHALL stop installing tokf as part of the active age
[summary compaction; truncated from 414 tokens]

## ssh_client/_index.md
---
children_hash: 563083a64489bad2364291a6105239b20ae35ab71e91a03d07bc6746532ce2c8
compression_ratio: 0.9976415094339622
condensation_order: 0
covers: [ssh_client_specification.md]
covers_token_total: 424
summary_level: d0
token_count: 423
type: summary
---
## ssh_client_specification.md
---
title: SSH Client Specification
summary: 'SSH client: declarative config via programs.ssh.* at modules/home/remote/ssh.nix, populating ~/.ssh/config, with explicit prohibition on secret management'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.408Z'
updatedAt: '2026-07-15T21:17:57.408Z'
---
## Reason
Document SSH client declarative config spec

## Raw Concept
**Task:**
Declarative SSH client configuration through Home Manager module

**Changes:**
- Added SSH client module at modules/home/remote/ssh.nix

**Files:**
- modules/home/remote/ssh.nix
- modules/home/remote/default.nix

**Flow:**
programs.ssh.enable=true -> module generates ~/.ssh/config

**Timestamp:** 2026-07-15

**Author:** tmux-ssh-mutagen-modules change

## Narrative
### Structure
Two requirements: (1) Declarative SSH client config with 3 scenarios about enablement, global defaults, and host-specific blocks, (2) No secret management with 3 scenarios confirming no known_hosts, authorized_keys, or private key manipulation.

### Dependencies
Uses Home Manager programs.ssh module. Host-specific blocks defined in hosts/arch/home.nix. Secrets managed externally (e.g., sops-nix).

### Highlights
Module explicitly SHALL NOT manage known_hosts, authorized_keys, or private key material. IdentityFile paths MAY reference existing user-managed keys. Host config MAY define Host blocks.

### Rules
Rule 1: The system SHALL provide declarative SSH client configuration via programs.ssh.*
Rule 2: The module SHALL be at modules/home/remote/ssh.nix
Rule 3: The module SHALL NOT manage known_hosts, authorized_keys, or priva
[summary compaction; truncated from 424 tokens]

## system_manager_foundation/_index.md
---
children_hash: 158b61d088ac54fe52543091513f5382870671486ad6e038af86fb3dea6ba8b4
compression_ratio: 0.9976359338061466
condensation_order: 0
covers: [system_manager_foundation.md]
covers_token_total: 423
summary_level: d0
token_count: 422
type: summary
---
## system_manager_foundation.md
---
title: System Manager Foundation
summary: 'System manager foundation: separate system-scoped config layer for non-NixOS hosts alongside Home Manager, with explicit privilege boundaries between system and user config'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.402Z'
updatedAt: '2026-07-15T21:17:57.402Z'
---
## Reason
Document system manager foundation spec

## Raw Concept
**Task:**
Establish declarative system-scoped configuration layer for non-NixOS hosts

**Changes:**
- Added system-scoped configuration layer
- Separated system and user module structures

**Files:**
- flake.nix (system-scoped outputs)

**Flow:**
maintainer evaluates flake -> system-scoped host entry available alongside user-scoped Home Manager entry

**Timestamp:** 2026-07-15

**Author:** add-system-manager change

## Narrative
### Structure
Two requirements: (1) System configuration layer exists for non-NixOS hosts, (2) System configuration structure is distinct from user configuration. Each with one scenario.

### Dependencies
Requires system-manager or equivalent system-scoped Nix tooling for non-NixOS hosts.

### Highlights
Explicit privilege boundaries: system-scoped modules and host entrypoints organized separately from user-scoped Home Manager modules. Daemon/root-owned settings go under dedicated system-scoped structure.

### Rules
Rule 1: The repository SHALL expose a declarative system-scoped configuration layer for supported non-NixOS hosts in addition to its existing Home Manager configuration
Rule 2: The repository SHALL organize system-scoped modules and host entrypoints sep
[summary compaction; truncated from 423 tokens]

## tmux/_index.md
---
children_hash: cd99e92a9cb25230b47531f29ff45abda3ec0682c518e1edfa9c0f58bbf502e2
compression_ratio: 0.997093023255814
condensation_order: 0
covers: [tmux_specification.md]
covers_token_total: 344
summary_level: d0
token_count: 343
type: summary
---
## tmux_specification.md
---
title: Tmux Specification
summary: 'Tmux capability: declarative config via programs.tmux.* at modules/home/tmux.nix, imported from modules/default.nix, populating ~/.config/tmux/tmux.conf'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.376Z'
updatedAt: '2026-07-15T21:17:57.376Z'
---
## Reason
Document tmux declarative config spec

## Raw Concept
**Task:**
Declarative tmux configuration through Home Manager module

**Changes:**
- Added tmux module at modules/home/tmux.nix
- Imported from modules/default.nix

**Files:**
- modules/home/tmux.nix
- modules/default.nix

**Flow:**
programs.tmux.enable=true -> module generates ~/.config/tmux/tmux.conf

**Timestamp:** 2026-07-15

**Author:** tmux-ssh-mutagen-modules change

## Narrative
### Structure
Single-requirement spec: declarative tmux configuration via programs.tmux.* with 3 scenarios covering enablement, extraConfig de
[summary compaction; truncated from 6056 tokens]

## overview/_index.md
---
children_hash: b70fef5051401523efff2ba954cab57f0ed7d56f5b9153793e8273ecbce40a8c
compression_ratio: 0.9985693848354793
condensation_order: 1
covers: [repo_overview.md]
covers_token_total: 699
summary_level: d1
token_count: 698
type: summary
---
## repo_overview.md
---
title: Repo Overview
summary: Dual-layer Nix flake config using system-manager and home-manager with dendritic module pattern, AI agent services, and 10+ core Nix ecosystem tools
tags: []
related: [nix_config/architecture.md, nix_config/structure.md]
keywords: []
createdAt: '2026-07-15T21:05:10.997Z'
updatedAt: '2026-07-15T21:05:10.997Z'
---
## Reason
Curating from README.md — goals, core technologies, commands, ownership boundaries

## Raw Concept
**Task:**
saurabhj Nix configuration — dual-layer flake for non-NixOS Arch Linux

**Changes:**
- Dual-layer: system-manager for daemon/root, home-manager for user-scoped concerns
- Dendritic pattern: small focused modules each owning one concern
- flake-parts for modular flake composition
- nh CLI for both layers (nh home switch, nh os switch)

**Files:**
- flake.nix
- README.md
- hosts/arch/home.nix
- hosts/arch/system.nix
- modules/default.nix
- modules/home/

**Flow:**
flake.nix → hosts/arch/home.nix → modules/default.nix → feature modules → config applied

**Timestamp:** 2026-07-15

**Author:** saurabhj

## Narrative
### Structure
Dual-layer flake: flake.nix entry point → flake-parts modular outputs: systemConfigs.arch (system-manager) and homeConfigurations.saurabhj (home-manager). Host configs under hosts/arch/ wire modules together. Modules organized as dendritic single-concern files under modules/home/. Custom packages under pkgs/ with overlay registration.

### Dependencies
Nix flake inputs: nixpkgs (unstable), flake-parts, home-manager, system-manager, sops-nix, direnv-instant, llm-agents, hermes-agent, codebase-memory-mcp, niks3, nvfetcher, and fish plugin flake inputs. Runtime: nh for switching, sops-nix for secrets, nix-direnv for automatic dev shells.

### Highlights
Core technologies: system-manager (daemon Nix on non-NixOS), home-manager (user environment), flake-parts (modular composition), nix-direnv, nh CLI, sops-nix (user-scoped secrets), nixfmt, statix/deadnix (linting), nix-output-monitor, comma for ephemeral packages, manix for doc search, nix-index for command-not-found.

### Rules
Rule 1: System layer (modules/system/) owns daemon config, system-level secrets, root-scope systemd services
Rule 2: Home layer (modules/home/) owns user packages, programs, shell config, user-scoped secrets, user timers
Rule 3: New home modules: create modules/home/<name>.nix, add to modules/default.nix imports, run nh home switch
Rule 4: New system modules: create modules/system/<name>.nix, add to modules/system/default.nix imports, run nh os switch

### Examples
GC Policy: automatic weekly via home-manager user timer nh-clean, retains 7 days of generations, auto-optimise-store enabled. Flake inputs count: 19 total inputs (9
[summary compaction; truncated from 699 tokens]

## structure/_index.md
---
children_hash: 46a3ac377a79a1291aca4fc3a550dfa41945881048ae99f080a73a5c6c6898ca
compression_ratio: 0.9990079365079365
condensation_order: 1
covers: [codebase_structure.md]
covers_token_total: 1008
summary_level: d1
token_count: 1007
type: summary
---
## codebase_structure.md
---
title: Codebase Structure
summary: 'Complete directory reference: hosts/, modules/, pkgs/, secrets/, openspec/ with naming conventions (kebab-case, default.nix pattern) and extension points'
tags: []
related: [nix_config/overview.md, nix_config/architecture.md]
keywords: []
createdAt: '2026-07-15T21:05:11.011Z'
updatedAt: '2026-07-15T21:05:11.011Z'
---
## Reason
Curating from STRUCTURE.md — directory purposes, naming conventions, where to add new code, module structure pattern

## Raw Concept
**Task:**
Nix config codebase structure — directory layout, purposes, naming conventions, and extension points

**Changes:**
- Directory purposes documented for all 12 top-level directories
- Module structure pattern: default.nix imports + single-concern .nix files, max 2 levels
- Naming conventions: kebab-case modules, UPPERCASE docs, lowercase host dirs
- Extension points: new packages, modules, dev tools, agents, hosts, secrets, systemd services

**Files:**
- STRUCTURE.md
- hosts/arch/home.nix
- modules/default.nix
- modules/home/
- pkgs/
- secrets/
- openspec/

**Flow:**
hosts/ (per-machine) → modules/ (reusable) → modules/home/ (features) → modules/home/dev-tools/ + agents/ (grouped concerns) → pkgs/ (derivations) → secrets/ (encrypted)

**Timestamp:** 2026-07-15

**Author:** saurabhj

## Narrative
### Structure
12 top-level directories. hosts/arch/home.nix: per-machine composition, sets identity and enables programs. modules/default.nix: single import point. modules/home/: flat .nix for single-concern modules + two subdirs (dev-tools/, agents/). modules/home/dev-tools/: languages (ast-grep, tree-sitter), mise (runtimes + npm tools), navi (cheatsheets). modules/home/agents/: pi, hermes, docs-mcp, bifrost (with config.json template), tools, agentmemory. pkgs/: snip, nix-search-tv-fzf, iii-engine, agentmemory (npm-based), xberg-cli, byterover-cli. secrets/: agents.yaml (central), pi-secrets.yaml, zsh-secrets.env (legacy), bifrost/.

### Dependencies
Entry points: flake.nix (flake-parts, 19 inputs, overlay, dev shell, homeConfigurations.saurabhj), hosts/arch/home.nix (imports ../../modules, enables pi/bifrost/docsMcp/agentTools/agentmemory/hermes-agent/devTools/miseTools), modules/default.nix (imports all home feature modules). Each module group follows: <group>/default.nix importing sub-modules with <group>/<module>.nix for single-concern modules.

### Highlights
Naming conventions: nix modules use kebab-case (zsh-abbr.nix, docs-mcp.nix), docs use UPPERCASE (ARCHITECTURE.md, STRUCTURE.md, README.md), host dirs lowercase (arch/), package dirs kebab-case (nix-search-tv-fzf/). No module group deeper than 2 levels. default.nix files are pure imports list (exception: dev-tools/default.nix also installs sysz). Tests: no test suite; validation via nh home switch or home-manager switch.

### Rules
Extension points:
- New Nix package: pkgs/<name>/default.nix → add to overlay in flake.nix
- New feature module (single): modules/home/<name>.nix → import in modules/default.nix
- New feature module (multi-file): modules/home/<group>/ → default.nix importing sub-modules
- New dev tool: modules/home/dev-tools/ → add file, import in dev-tools/default.nix
- New agent: modules/home/agents/<name>.nix → import in agents/default.nix
- New host: hosts/<hostname>/home.nix → add homeConfigurations in flake.nix
- New secret: add key to secrets/agents.yaml → declare sops placeholder in modules/home/sops.nix
- New systemd user service: modules/home/agents/ → follow bifrost/docs-mcp/agentmemory pattern
- Pinned flake input: add to inputs in flake.nix, pass via extraSpecialArgs

### Examples
Shell config: zsh via antidote (powerlevel10k, fzf-tab, zsh-vi-mode, eza, pay-respects), zsh-abbr for git/nix/file/systemd shortcuts. OpenCode: symlinks ~/.config/open
[summary compaction; truncated from 9027 tokens]