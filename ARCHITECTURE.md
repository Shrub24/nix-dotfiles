# Architecture

## Directory Layout

```
.
├── flake.nix                    # Flake entry point — inputs, overlay, per-host configs
├── ARCHITECTURE.md              # This file
├── README.md
├── sgconfig.yml                 # ast-grep custom language config (MATLAB tree-sitter)
├── .envrc                       # direnv: `use flake . --impure`
├── .sops.yaml                   # sops-nix encryption rules
│
├── hosts/                       # Per-machine / per-user compositions
│   └── arch/
│       └── home.nix             #   Host entrypoint: identity, imports all modules
│
├── modules/
│   ├── default.nix              # Single entry point — imports all home sub-modules
│   └── home/                    # Home Manager feature modules
│       ├── nix.nix              #   Nix CLI, settings, GC, nix-index, unfree policy
│       ├── direnv.nix           #   direnv + direnv-instant
│       ├── sops.nix             #   sops-nix secrets decryption
│       ├── zsh.nix              #   Zsh config, antidote plugins, aliases, fzf, zoxide
│       ├── zsh-abbr.nix         #   zsh-abbr (user & global abbreviations)
│       ├── dev-tools/           #   CLI and language development tools
│       │   ├── default.nix      #     Imports sub-modules
│       │   ├── languages.nix    #     ast-grep, tree-sitter, extra grammars
│       │   ├── mise.nix         #     mise-en-place (node, pnpm, bun, npm tools)
│       │   └── navi.nix         #     navi CLI cheatsheets
│       └── agents/              #   AI agent modules
│           ├── default.nix      #     Composes pi, hermes, bifrost, tools
│           ├── pi.nix           #     pi (llm-agents) — settings, MCP, search, permissions
│           ├── hermes.nix       #     hermes-agent — config, systemd user service
│           ├── bifrost/         #     Bifrost MCP gateway
│           │   ├── default.nix  #       Systemd service + config rendering
│           │   └── config.json  #       Config template with envsubst vars
│           └── tools.nix        #     Agent CLI tools (tokf, codebase-memory-mcp)
│
├── pkgs/                        # Custom derivations (not in nixpkgs)
│   └── tokf/
│       └── default.nix
│
├── secrets/                     # Encrypted secrets (sops-nix)
│   ├── zsh-secrets.env          #   Shell secrets (dotenv format)
│   ├── pi-secrets.yaml          #   Pi telegram secret (YAML format)
│   └── bifrost/                 #   Bifrost gateway secrets
│
└── openspec/                    # OpenSpec change proposals
    └── changes/
        └── hermes-agent/        # Hermes agent proposal + specs
```

## Principles

- **Derivations → `pkgs/`** — every custom build recipe lives under `pkgs/`. Exposed via overlay so `pkgs.<name>` works everywhere.
- **Feature modules → `modules/home/`** — each module file owns one concern. Imported by the module entry point; never by other feature modules.
- **Dev-tools → `modules/home/dev-tools/`** — grouped concern for CLI/language development tools (ast-grep, tree-sitter, mise, navi). Wired through `dev-tools/default.nix`.
- **Agent modules → `modules/home/agents/`** — concern-grouped under the home-manager tree, with `agents/default.nix` composing pi, hermes, bifrost, tools.
- **Host compositions → `hosts/<hostname>/home.nix`** — the only place that sets host-specific identity (`home.username`, `home.stateVersion`) and enables programs. Imports `../../modules` to pull in all feature modules.
- **`modules/default.nix` is the single module entry point** — imports `./home/nix.nix`, `./home/direnv.nix`, `./home/sops.nix`, `./home/zsh.nix`, `./home/zsh-abbr.nix`, `./home/dev-tools`, and `./home/agents`. Host configs only need `imports = [ ../../modules ]`.
- **`flake.nix` is pure wiring** — inputs, the local overlay (tokf), the dev shell, and the per-host `homeConfiguration` block. No module logic lives here.

## Data Flow

```
flake.nix
  └─┬─ hosts/arch/home.nix          (sets identity, enables programs)
    └─ modules/default.nix          (single import point)
       ├─ modules/home/nix.nix      (Nix CLI + settings)
       ├─ modules/home/direnv.nix   (direnv + direnv-instant)
       ├─ modules/home/sops.nix     (sops-nix secrets)
       ├─ modules/home/zsh.nix      (Zsh via antidote)
       ├─ modules/home/zsh-abbr.nix (zsh-abbr abbreviations)
       ├─ modules/home/dev-tools/   (languages, mise, navi)
       └─ modules/home/agents/      (pi, hermes, bifrost, tools)
```

The host config (`hosts/arch/home.nix`) is the sole wiring point for enabling `programs.pi`, `programs.hermes`, `programs.bifrost`, `programs.agentTools`, `programs.devTools`, and `programs.miseTools`. Modules expose options; the host config sets their values.

## Key Abstractions

### Module Options Pattern

Modules in `modules/home/` define NixOS/home-manager options with `lib.mkOption`, then wire them in `config` blocks. The host config sets option values, keeping module logic reusable and host-specific values isolated.

Example flow — pi agent:
1. `modules/home/agents/pi.nix` defines `programs.pi.*` options (settings, mcp, search, permissions, subagents)
2. `hosts/arch/home.nix` sets `programs.pi = { ... }` with provider, models, MCP servers, permission rules
3. `modules/home/agents/pi.nix` renders config files from these options into `~/.pi/agent/`

### Secret Management

Secrets follow sops-nix with two encrypted files:
- `secrets/zsh-secrets.env` — dotenv format, decrypted to `~/.secrets/zsh-secrets.env`, sourced by zsh `envExtra`
- `secrets/pi-secrets.yaml` — YAML format, contains `telegram_bot_token` for pi-telegram bootstrap

### Systemd User Services

Two systemd user services managed here:
- **Bifrost** (`modules/home/agents/bifrost/default.nix`) — MCP gateway server on port 8765, runs via pnpx
- **Hermes agent** (`modules/home/agents/hermes.nix`) — gateway daemon, runs `hermes gateway`

## Noteworthy Config Details

- **Zsh** uses antidote for plugin management, powerlevel10k theme, fzf-tab completion, zsh-vi-mode
- **Zsh abbreviations** provide git/Nix/file-system shorthand through `zsh-abbr`
- **Mise** manages node, pnpm, bun runtime versions plus npm-global tools (ocx, codeburn, neovim, matlab-language-server, openspec, happier-dev)
- **Pi permissions** follow a layered approach: defaults in `pi.nix`, host overrides via `lib.recursiveUpdate`
- **Unfree packages** whitelist uses `nixpkgs.config.allowUnfreePredicate` — currently only `zsh-abbr`
- **direnv-instant** enables instant shell entry via cached evaluation — `direnv-instant` hook added in zsh `initContent` at priority 2000
- **ast-grep** is configured with a MATLAB custom language parser at `sgconfig.yml`
