# Architecture

## Directory Layout

```
.
├── flake.nix                      # Flake entry point — inputs, overlay, per-host configs
├── flake.lock                   # Pinned flake inputs
├── ARCHITECTURE.md              # This file
├── STRUCTURE.md                 # Codebase structure reference
├── README.md
├── .envrc                       # direnv: `use flake . --impure`
├── .sops.yaml                   # sops-nix encryption rules
├── .gitignore
├── hosts/                       # Per-machine / per-user compositions
│   └── arch/
│       └── home.nix             # Host entrypoint: identity, imports all modules
│
├── modules/                     # Home Manager modules
│   ├── default.nix              # Single entry point — imports all home sub-modules
│   └── home/                    # Home Manager feature modules
│       ├── nix.nix              # Nix CLI, settings, GC, nix-index, unfree policy
│       ├── direnv.nix           # direnv + direnv-instant
│       ├── sops.nix             # sops-nix secrets decryption (YAML-backed placeholders)
│       ├── zsh.nix              # Zsh config, antidote plugins, aliases, fzf, zoxide, eza
│       ├── zsh-abbr.nix         # zsh-abbr (user & global abbreviations)
│       ├── tmux.nix             # tmux session configuration
│       ├── opencode.nix         # OpenCode config symlinks (~/.config/opencode, ~/.agents)
│       ├── dev-tools/           # CLI and language development tools
│       │   ├── default.nix      # Imports sub-modules + sysz package
│       │   ├── languages.nix    # ast-grep, tree-sitter, extra grammars, sgconfig.yml
│       │   ├── mise.nix         # mise-en-place (node, pnpm, bun, npm tools)
│       │   └── navi.nix         # navi CLI cheatsheets
│       │
│       └── agents/              # AI agent modules
│           ├── default.nix      # Composes pi, hermes, docs-mcp, bifrost, tools, agentmemory
│           ├── pi.nix           # pi (llm-agents) — settings, MCP, search, permissions
│           ├── hermes.nix        # hermes-agent — config, from flake input
│           ├── docs-mcp.nix     # Grounded Docs MCP Server — systemd service
│           ├── bifrost/        # Bifrost MCP gateway
│           │   ├── default.nix  # Systemd service (bunx) + config rendering
│           │   └── config.json  # Config template with envsubst vars
│           ├── tools.nix         # Agent CLI tools (tokf, codebase-memory-mcp)
│           └── agentmemory.nix  # Persistent memory daemon + systemd service
│
├── pkgs/                        # Custom derivations (not in nixpkgs)
│   ├── tokf/
│   │   └── default.nix
│   ├── nix-search-tv-fzf/
│   │   └── default.nix
│   ├── iii-engine/
│   │   └── default.nix
│   └── agentmemory/             # Persistent memory for AI coding agents (npm-based)
│       ├── default.nix
│       └── package-lock.json
│
├── secrets/                     # Encrypted secrets (sops-nix)
│   ├── agents.yaml              # Central YAML secrets store (API keys, tokens)
│   ├── pi-secrets.yaml          # Pi telegram secret (YAML format)
│   ├── zsh-secrets.env          # Legacy shell secrets (dotenv, superseded by sops template)
│   └── bifrost/                 # Bifrost gateway secrets
│
├── openspec/                    # OpenSpec change proposals
│   ├── config.yaml              # OpenSpec project configuration
│   ├── specs/                   # Reusable spec definitions
│   └── changes/
│       ├── hermes-agent/        # Hermes agent proposal + specs
│       ├── agentmemory/         # Agent memory system proposal + specs
│       └── archive/            # Archived proposals
│
├── raw/                         # Live symlink targets (not in nix store)
│   ├── agents/                  # → ~/.agents via opencode.nix
│   └── opencode/               # → ~/.config/opencode via opencode.nix
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

## Principles

- **Derivations → `pkgs/`** — every custom build recipe lives under `pkgs/`. Exposed via overlay so `pkgs.<name>` works everywhere.
- **Feature modules → `modules/home/`** — each module file owns one concern. Imported by `modules/default.nix`; never by other feature modules.
- **Dev-tools → `modules/home/dev-tools/`** — grouped concern for CLI/language development tools (ast-grep, tree-sitter, mise, navi, sysz). Wired through `dev-tools/default.nix`.
- **Agent modules → `modules/home/agents/`** — concern-grouped under the home-manager tree, with `agents/default.nix` composing pi, hermes, docs-mcp, bifrost, tools, and agentmemory.
- **Host compositions → `hosts/<hostname>/home.nix`** — the only place that sets host-specific identity (`home.username`, `home.stateVersion`) and enables programs. Imports `../../modules` to pull in all feature modules.
- **`modules/default.nix` is the single module entry point** — imports `./home/nix.nix`, `./home/direnv.nix`, `./home/sops.nix`, `./home/zsh.nix`, `./home/zsh-abbr.nix`, `./home/opencode.nix`, `./home/tmux.nix`, `./home/dev-tools`, and `./home/agents`. Host configs only need `imports = [../../modules]`.
- **`flake.nix` is pure wiring** — inputs, the local overlay (tokf, nix-search-tv-fzf, iii-engine, agentmemory), the dev shell, and the per-host `homeConfigurations` block. No module logic lives here.
- **`pkgs/` flake overlay** — all custom packages are registered via `perSystem` overlay in `flake.nix` so they're available as `pkgs.<name>` everywhere.

## Data Flow

```
flake.nix
  └─┬─ hosts/arch/home.nix          (sets identity, enables programs)
    └─ modules/default.nix        (single import point)
       ├─ modules/home/nix.nix     (Nix CLI + settings, unfree whitelist)
       ├─ modules/home/direnv.nix  (direnv + direnv-instant)
       ├─ modules/home/sops.nix    (sops-nix secrets via agents.yaml placeholders)
       ├─ modules/home/zsh.nix     (Zsh via antidote, fzf, zoxide, eza, pay-respects)
       ├─ modules/home/zsh-abbr.nix (zsh-abbr abbreviations)
       ├─ modules/home/opencode.nix (OpenCode/agents symlinks)
       ├─ modules/home/tmux.nix    (tmux session configuration)
       ├─ modules/home/dev-tools/  (languages, mise, navi)
       └─ modules/home/agents/     (pi, hermes, docs-mcp, bifrost, tools, agentmemory)
```

The host config (`hosts/arch/home.nix`) is the sole wiring point for enabling `programs.pi`, `programs.bifrost`, `programs.docsMcp`, `programs.agentTools`, `programs.devTools`, `programs.agentmemory`, `programs.hermes-agent`, `programs.miseTools`, and `programs.tmux`. Modules expose options; the host config sets their values.

## Key Abstractions

### Module Options Pattern

Modules in `modules/home/` define NixOS/home-manager options with `lib.mkOption`, then wire them in `config` blocks. The host config sets option values, keeping module logic reusable and host-specific values isolated.

Example flow — pi agent:
1. `modules/home/agents/pi.nix` defines `programs.pi.*` options (settings, mcp, search, permissions, subagents)
2. `hosts/arch/home.nix` sets `programs.pi = { ... }` with provider, models, MCP servers, permission rules
3. `modules/home/agents/pi.nix` renders config files from these options into `~/.pi/agent/`

### Secret Management

Secrets follow sops-nix with a centralized YAML-backed placeholder approach:

- `secrets/agents.yaml` — single YAML file holding all API keys and tokens (github, google, openrouter, jina, tavily, brave, firecrawl, context7, openai, minimax, crofai, opencode)
- `secrets/pi-secrets.yaml` — `telegram_bot_token` for pi-telegram bootstrap
- `modules/home/sops.nix` declares sops placeholders per key, renders template files:
  - `zsh-secrets.env` — shell environment variables sourced by zsh `envExtra`
  - `docs-mcp.env` — `OPENAI_API_KEY` for the docs-mcp service
  - `bifrost-config.json` — decrypted into `~/.config/bifrost/config.json`
  - `agentmemory.env` — decrypted into `~/.agentmemory/.env` with OPENAI_API_KEY, OPENROUTER_API_KEY, MINIMAX_API_KEY, GOOGLE_API_KEY

The `secrets/zsh-secrets.env` dotenv file is legacy; all new secrets go into `secrets/agents.yaml` and reference via sops placeholders.

### Systemd User Services

Four systemd user services managed here:
- **Bifrost** (`modules/home/agents/bifrost/default.nix`) — MCP gateway server on port 8765, runs via bunx
- **Docs MCP** (`modules/home/agents/docs-mcp.nix`) — Grounded Docs MCP Server on port 6280, runs via bunx with OpenAI-compatible embedding model
- **Hermes agent** (`modules/home/agents/hermes.nix`) — gateway daemon, runs `hermes gateway`
- **Agentmemory** (`modules/home/agents/agentmemory.nix`) — persistent memory daemon, runs `agentmemory` on port 3111 with viewer on port 3113

## Noteworthy Config Details

- **Zsh** uses antidote for plugin management, powerlevel10k theme, fzf-tab completion, zsh-vi-mode, eza for `ls`, pay-respects for command correction
- **Zsh abbreviations** provide git/Nix/file-system/systemd/journalctl shorthand through `zsh-abbr`
- **Mise** manages node, pnpm, bun runtime versions plus npm-global tools (ocx, codeburn, neovim, matlab-language-server, openspec, happier-dev)
- **Pi permissions** follow a layered approach: defaults in `pi.nix`, host overrides via `lib.recursiveUpdate`
- **Unfree packages** whitelist uses `nixpkgs.config.allowUnfreePredicate` — currently `zsh-abbr` and `iii-engine`
- **direnv-instant** enables instant shell entry via cached evaluation — `direnv-instant` hook added in zsh `initContent` at priority 2000
- **ast-grep** is configured with a MATLAB custom language parser via `modules/home/dev-tools/languages.nix` (writes `~/.config/ast-grep/sgconfig.yml`)
- **sops templates** render service configs at activation time: `zsh-secrets.env` from agents.yaml placeholders, `bifrost-config.json` from config.json template, `docs-mcp.env` for the docs-mcp service, and `agentmemory.env` for the agentmemory daemon
- **OpenCode symlinks** (`modules/home/opencode.nix`) link `~/.config/opencode` → `$repoRoot/raw/opencode` and `~/.agents` → `$repoRoot/raw/agents` as out-of-store symlinks
- **Flake-parts** provides the Nix flake structure (`flake-parts.lib.mkFlake`), with `perSystem` for formatter and dev shell, and a top-level `flake` block for `homeConfigurations`
- **Agentmemory service** (`modules/home/agents/agentmemory.nix`) defines `programs.agentmemory.*` options: `package` (defaults to `pkgs.agentmemory`), `stateDir` (defaults to `~/.agentmemory`), `settings` (non-sensitive env vars), `environmentFiles` (sops template for secrets), and `hermesPlugin` (deploys memory provider plugin to `~/.hermes/plugins/agentmemory`)
- **Hermes + agentmemory integration** — when both are enabled, `modules/home/agents/hermes.nix` configures hermes to use agentmemory as its memory provider via the `@agentmemory/mcp` MCP server and `memory.provider = "agentmemory"` setting
- **Pi telegram bootstrap** — `hosts/arch/home.nix` includes a `piTelegramBootstrap` activation hook that initializes `~/.pi/agent/telegram.json` from the sops-decrypted `telegram_bot_token` secret (one-shot, preserves runtime state)
- **tmux** — `modules/home/tmux.nix` provides sensible base settings for persistent remote sessions via `programs.tmux`

(End of file - total 147 lines)
