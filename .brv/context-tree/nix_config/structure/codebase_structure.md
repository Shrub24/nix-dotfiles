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
Shell config: zsh via antidote (powerlevel10k, fzf-tab, zsh-vi-mode, eza, pay-respects), zsh-abbr for git/nix/file/systemd shortcuts. OpenCode: symlinks ~/.config/opencode → ${appsDir}/opencode and ~/.agents → ${appsDir}/agents via opencode.nix. Agentmemory: npm package with iii-engine in PATH, Hermes plugin deploys memory provider to ~/.hermes/plugins/agentmemory.
