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