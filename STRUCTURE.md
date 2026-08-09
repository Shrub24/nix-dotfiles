# Codebase Structure

## Directory Layout

```
[project-root]/
├── flake.nix                    # Flake entry point (flake-parts)
├── flake.lock                   # Pinned flake inputs
├── ARCHITECTURE.md               # Architecture reference
├── STRUCTURE.md                 # This file
├── README.md                    # Project overview & quickstart
├── .envrc                       # direnv: `use flake . --impure`
├── .sops.yaml                   # sops-nix encryption rules
├── .gitignore
├── niri.config.kdl.imperative-backup  # Pre-migration niri config backup
│
├── hosts/                       # Per-machine configurations
│   └── arch/
│       └── home.nix
│
├── modules/                     # Home Manager modules
│   ├── default.nix              # Module entry point
│   └── home/                    # Feature modules
│       ├── nix.nix              # Nix CLI & settings
│       ├── direnv.nix           # direnv integration
│       ├── sops.nix             # Secrets management (YAML-backed placeholders)
│       ├── zsh.nix              # Zsh shell config
│       ├── zsh-abbr.nix         # Zsh abbreviations
│       ├── tmux.nix             # tmux session settings
│       ├── opencode.nix         # OpenCode/agents symlinks → ../apps
│       ├── niri.nix             # niri compositor + Noctalia shell
│       ├── dev-tools/           # Dev tools (languages, mise, navi)
│       │   ├── default.nix
│       │   ├── languages.nix
│       │   ├── mise.nix
│       │   └── navi.nix
│       └── agents/              # AI agent configs
│           ├── default.nix
│           ├── pi.nix
│           ├── hermes.nix
│           ├── docs-mcp.nix
│           ├── bifrost/
│           │   ├── default.nix
│           │   └── config.json
│           ├── tools.nix
│           └── agentmemory.nix
│
├── pkgs/                        # Custom Nix derivations
│   ├── snip/
│   │   └── default.nix
│   ├── nix-search-tv-fzf/
│   │   └── default.nix
│   ├── iii-engine/
│   │   └── default.nix
│   └── agentmemory/
│       ├── default.nix
│       └── package-lock.json
│
├── secrets/                     # Encrypted secrets (sops-nix)
│   ├── agents.yaml              # Central YAML secrets store
│   ├── pi-secrets.yaml          # Pi telegram bot token
│   ├── zsh-secrets.env          # Legacy shell secrets dotenv
│   └── bifrost/                 # Bifrost gateway secrets
│
├── openspec/                    # OpenSpec change proposals
│   ├── config.yaml              # Project configuration
│   ├── specs/                   # Reusable spec definitions
│   └── changes/
│       ├── hermes-agent/        # Hermes agent proposal
│       ├── agentmemory/         # Agent memory system proposal
│       └── archive/            # Archived proposals
│
├── .skills/                     # Dendritic skills cache
│   └── dendritic-nix/
│       └── references/
│
└── .opencode/                   # OpenCode plugin/skill artifacts
    ├── commands/
    ├── magic-context/
    ├── plugins/
    └── skills/
```

## Directory Purposes

**`hosts/`:**
- Purpose: Per-machine compositions that wire modules together with host-specific identity
- Contains: One subdirectory per host (`arch/`)
- Key files: `hosts/arch/home.nix` — sets `home.username`, `home.stateVersion`, enables programs

**`modules/`:**
- Purpose: Reusable Home Manager modules organized by concern
- Contains: `default.nix` entry point + `home/` with all feature modules
- Key files: `modules/default.nix` — single import point for host configs

**`modules/home/`:**
- Purpose: Core feature modules (nix, direnv, sops, zsh, opencode, tmux, niri) at top level
- Contains: Flat `.nix` files for single-concern modules plus two subdirectories

**`modules/home/dev-tools/`:**
- Purpose: CLI and language development tools grouped together
- Contains: `default.nix` composing languages, mise, navi; also installs `sysz`

**`modules/home/agents/`:**
- Purpose: AI agent configurations (pi, hermes, docs-mcp, Bifrost, tools, agentmemory, litellm)
- Contains: `default.nix` composing pi, hermes, docs-mcp, bifrost, tools, agentmemory, litellm

**`modules/home/agents/bifrost/`:**
- Purpose: Bifrost MCP gateway module with config template
- Contains: `default.nix` (systemd service via bunx) + `config.json` (envsubst template)

**`modules/home/agents/docs-mcp.nix`:**
- Purpose: Grounded Docs MCP Server — systemd service on port 6280
- Uses: bunx with OpenAI-compatible embedding model, sops template for API key

**`modules/home/agents/agentmemory.nix`:**
- Purpose: Agentmemory persistent memory daemon — systemd service on port 3111
- Uses: nix package `pkgs.agentmemory` (npm-based), sops template for API keys
- Features: Hermes plugin integration deploys memory provider to `~/.hermes/plugins/agentmemory`

**`modules/home/agents/litellm/`:**
- Purpose: LiteLLM LLM gateway + Headroom context compression sidecar
- Contains: `default.nix` (systemd services, activation hooks), `generated.nix` (config/model catalog, guardrail + MCP bridge config), `aliases.nix` (model aliases)
- Uses: OCI image from `pkgs/litellm/oci.nix` (patched `litellm-database`), official Headroom 0.33.0-code OCI image, podman runtime, sops template for API keys
- Design: OCI retained because Prisma client/database migrations are impractical to package natively; image loaded once at activation, not per-start; `StartLimitBurst`/`StartLimitIntervalSec` on both services prevent runaway restart loops; native LiteLLM pre-call guardrail active (`default_on = true`); stdio MCP bridge exposes `headroom_retrieve` to OpenCode

**`modules/home/opencode.nix`:**
- Purpose: Creates out-of-store symlinks for OpenCode and agent configs
- Links: `~/.config/opencode` → `${appsDir}/opencode`, `~/.agents` → `${appsDir}/agents` (`appsDir = /home/saurabhj/.dotfiles/apps`, sibling of the repo via `extraSpecialArgs`)

**`modules/home/niri.nix`:**
- Purpose: Wayland desktop session — niri compositor + Noctalia shell
- Uses: `wayland.windowManager.niri` (native HM module; structured `settings` + verbatim KDL `extraConfig`); `programs.noctalia` from `inputs.noctalia.homeModules.default` with `package = pkgs.noctalia` (nixpkgs prebuilt)
- Note: `xdg.configFile."niri/config.kdl".force = true` replaces the imperative config; pre-migration backup at `niri.config.kdl.imperative-backup`

**`pkgs/`:**
- Purpose: Custom Nix derivations not available in nixpkgs
- Contains: One directory per package (`snip/`, `nix-search-tv-fzf/`, `iii-engine/`, `agentmemory/`, `litellm/`)

**`secrets/`:**
- Purpose: Encrypted secrets managed by sops-nix
- Contains: `agents.yaml` (central YAML store), `pi-secrets.yaml` (telegram token), `zsh-secrets.env` (legacy), `bifrost/` gateway secrets

**`openspec/changes/`:**
- Purpose: OpenSpec change proposals
- Contains: `hermes-agent/` (hermes agent proposal), `agentmemory/` (agent memory system), `archive/` (archived proposals)

## Key File Locations

**Entry Points:**
- `flake.nix`: Flake entry point — defines inputs (9 flake inputs), flake-parts based overlay, dev shell, `homeConfigurations.saurabhj`
- `hosts/arch/home.nix`: Host entry point — imports `../../modules`, sets identity, enables pi/bifrost/docsMcp/agentTools/agentmemory/hermes-agent/devTools/miseTools
- `modules/default.nix`: Module entry point — imports all home feature modules/groups

**Configuration:**
- `modules/home/nix.nix`: Nix CLI settings, experimental features, GC policy, unfree whitelist (zsh-abbr, iii-engine)
- `modules/home/direnv.nix`: direnv + direnv-instant configuration (imports direnv-instant flake module)
- `modules/home/sops.nix`: sops-nix with YAML-backed placeholders from `secrets/agents.yaml`, renders 4 templates
- `modules/home/niri.nix`: niri compositor + Noctalia shell — `wayland.windowManager.niri` (`settings` + `extraConfig`), `programs.noctalia` (`package = pkgs.noctalia`), force-replaces imperative `~/.config/niri/config.kdl`
- `.sops.yaml`: Encryption key and file rules for sops

**Shell:**
- `modules/home/zsh.nix`: Zsh through antidote — plugins, powerlevel10k, history, fzf, zoxide, eza, pay-respects
- `modules/home/zsh-abbr.nix`: Zsh abbreviations — git, Nix, file system, systemd, journalctl, global pipe shortcuts

**OpenCode:**
- `modules/home/opencode.nix`: Out-of-store symlinks — `~/.config/opencode` → `${appsDir}/opencode`, `~/.agents` → `${appsDir}/agents` (appsDir = `../apps`, sibling of repo)

**Development Tools:**
- `modules/home/dev-tools/languages.nix`: ast-grep, tree-sitter, matlab grammar, writes `~/.config/ast-grep/sgconfig.yml`
- `modules/home/dev-tools/mise.nix`: mise-en-place for node/pnpm/bun runtimes + npm global tools
- `modules/home/dev-tools/navi.nix`: navi CLI cheatsheets with fzf integration

**Agents:**
- `modules/home/agents/pi.nix`: pi coding agent — full option tree for settings, MCP, search, permissions, subagents
- `modules/home/agents/hermes.nix`: hermes-agent — imports flake module from `hermes-agent-src` input; integrates with agentmemory as memory provider when both are enabled
- `modules/home/agents/docs-mcp.nix`: Grounded Docs MCP Server — systemd service, bunx, sops.env template
- `modules/home/agents/bifrost/default.nix`: Bifrost MCP gateway — systemd service via bunx, sops-template config
- `modules/home/agents/tools.nix`: Agent CLI tools — snip derivation, codebase-memory-mcp from flake input
- `modules/home/agents/agentmemory.nix`: Agentmemory persistent memory daemon — defines `programs.agentmemory.*` options, systemd service, optional Hermes plugin deployment
- `modules/home/agents/litellm/default.nix`: LiteLLM gateway + Headroom sidecar — OCI via podman, one-time image load at activation, restart burst limits, sops template for env

**Secrets (sops-encrypted):**
- `secrets/agents.yaml`: Central YAML store — all API keys (github, google, openrouter, jina, tavily, brave, firecrawl, context7, openai, minimax, crofai, opencode)
- `secrets/pi-secrets.yaml`: Pi telegram bot token
- `secrets/zsh-secrets.env`: Legacy dotenv (superseded by agents.yaml + sops template)

**Overlay:**
- `pkgs/snip/default.nix`: Custom snip package
- `pkgs/nix-search-tv-fzf/default.nix`: nstv — fzf wrapper around nix-search-tv
- `pkgs/iii-engine/default.nix`: III engine package
- `pkgs/agentmemory/default.nix`: Agentmemory npm package — persistent memory for AI agents, wraps `@agentmemory/agentmemory` from npm registry, wraps with iii-engine in PATH
- `pkgs/litellm/oci.nix`: LiteLLM patched OCI image — pulls `litellm-database` base, applies compatibility patches via custom entrypoint
- `pkgs/litellm/patches/`: Build-time patches for litellm (streaming empty-choices, prefix-message stripping)
- `flake.nix` (lines 60-67): Overlay registrations for all custom packages

## Naming Conventions

**Files:**
- Nix modules: Lowercase, kebab-case, `.nix` extension — `zsh-abbr.nix`, `languages.nix`, `docs-mcp.nix`, `agentmemory.nix`
- Config files: Standard names — `config.json`, `.sops.yaml`
- Documentation: Uppercase — `ARCHITECTURE.md`, `STRUCTURE.md`, `README.md`

**Directories:**
- Module groupings: Lowercase, kebab-case — `dev-tools/`, `home/`, `agents/`
- Host directories: Lowercase — `arch/`
- Submodule directories: Same as module name — `bifrost/` contains `default.nix`
- Package directories: Lowercase, kebab-case — `nix-search-tv-fzf/`, `agentmemory/`, `iii-engine/`

## Module Structure Pattern

Each module group directory follows:

```
<group>/default.nix     # imports all sub-modules in the group
<group>/<module>.nix    # single-concern module with options + config
```

No module group is deeper than two levels. Every `default.nix` is purely an `imports` list — no options or config live there (except `dev-tools/default.nix` which also installs `sysz`).

## Where to Add New Code

**New Nix package:** `pkgs/<package-name>/default.nix` — add to the overlay in `flake.nix`

**New feature module (single file):** `modules/home/<module-name>.nix` — add import to `modules/default.nix`

**New feature module (multi-file group):** `modules/home/<group-name>/` with `default.nix` importing sub-modules

**New dev tool:** `modules/home/dev-tools/` — add file and import in `dev-tools/default.nix`; add option to `programs.devTools.*` in `languages.nix` if it has an enable toggle

**New agent:** `modules/home/agents/<agent-name>.nix` — add import to `agents/default.nix`
For multi-file agents: `modules/home/agents/<agent-name>/` with `default.nix`

**New host:** `hosts/<hostname>/home.nix` — add `homeConfigurations.<hostname>` in `flake.nix`

**New secret:** Add key to `secrets/agents.yaml` (YAML format) — declare sops placeholder + secret in `modules/home/sops.nix`

**New systemd user service:** Add to `modules/home/agents/` — follow the pattern in `bifrost/default.nix`, `docs-mcp.nix`, or `agentmemory.nix`

**Pinned flake input:** Add to `inputs` in `flake.nix`, pass via `extraSpecialArgs`

## Tests

This project has no test suite. All changes are validated by building with `nh home switch` or `home-manager switch --flake .#saurabhj`.

(End of file - total 235 lines)
