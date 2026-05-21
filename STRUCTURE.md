# Codebase Structure

## Directory Layout

```
[project-root]/
├── flake.nix                    # Flake entry point
├── flake.lock                   # Pinned flake inputs
├── ARCHITECTURE.md              # Architecture reference
├── STRUCTURE.md                 # This file
├── README.md                    # Project overview & quickstart
├── sgconfig.yml                 # ast-grep custom language config
├── .envrc                       # direnv: `use flake . --impure`
├── .sops.yaml                   # sops-nix encryption rules
├── .gitignore
│
├── hosts/                       # Per-machine configurations
│   └── arch/
│       └── home.nix
│
├── modules/                     # Home Manager modules
│   ├── default.nix              #   Module entry point
│   └── home/                    #   Feature modules
│       ├── nix.nix              #     Nix CLI & settings
│       ├── direnv.nix           #     direnv integration
│       ├── sops.nix             #     Secrets management
│       ├── zsh.nix              #     Zsh shell config
│       ├── zsh-abbr.nix         #     Zsh abbreviations
│       ├── dev-tools/           #     Dev tools (languages, mise, navi)
│       │   ├── default.nix
│       │   ├── languages.nix
│       │   ├── mise.nix
│       │   └── navi.nix
│       └── agents/              #     AI agent configs
│           ├── default.nix
│           ├── pi.nix
│           ├── hermes.nix
│           ├── bifrost/
│           │   ├── default.nix
│           │   └── config.json
│           └── tools.nix
│
├── pkgs/                        # Custom Nix derivations
│   └── tokf/
│       └── default.nix
│
├── secrets/                     # Encrypted secrets (sops-nix)
│   ├── zsh-secrets.env
│   ├── pi-secrets.yaml
│   └── bifrost/
│
└── openspec/                    # OpenSpec change proposals
    └── changes/
        └── hermes-agent/
            ├── design.md
            ├── proposal.md
            ├── specs/
            │   ├── agent-core/
            │   ├── mcp-servers/
            │   ├── permissions/
            │   └── subagents/
            └── tasks.md
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
- Purpose: Core feature modules (nix, direnv, sops, zsh) at top level
- Contains: Flat `.nix` files for single-concern modules

**`modules/home/dev-tools/`:**
- Purpose: CLI and language development tools grouped together
- Contains: `default.nix` composing languages, mise, navi

**`modules/home/agents/`:**
- Purpose: AI agent configurations (pi, hermes, Bifrost, tools)
- Contains: `default.nix` composing pi, hermes, bifrost, tools submodules

**`modules/home/agents/bifrost/`:**
- Purpose: Bifrost MCP gateway module with config template
- Contains: `default.nix` (systemd service) + `config.json` (envsubst template)

**`pkgs/`:**
- Purpose: Custom Nix derivations not available in nixpkgs
- Contains: One directory per package (`tokf/`)

**`secrets/`:**
- Purpose: Encrypted secrets managed by sops-nix
- Contains: `zsh-secrets.env` (dotenv), `pi-secrets.yaml` (YAML), `bifrost/` gateway secrets

**`openspec/changes/hermes-agent/`:**
- Purpose: OpenSpec change proposal for hermes-agent feature
- Contains: Design doc, proposal, specs (agent-core, mcp-servers, permissions, subagents), tasks

## Key File Locations

**Entry Points:**
- `flake.nix`: Flake entry point — defines inputs, overlay, dev shell, `homeConfigurations.saurabhj`
- `hosts/arch/home.nix`: Host entry point — imports `../../modules`, sets identity, enables programs
- `modules/default.nix`: Module entry point — imports all feature modules from `modules/home/`

**Configuration:**
- `modules/home/nix.nix`: Nix CLI settings, experimental features, GC policy, unfree whitelist
- `modules/home/direnv.nix`: direnv + direnv-instant configuration
- `modules/home/sops.nix`: sops-nix secret paths and decryption rules
- `.sops.yaml`: Encryption key and file rules for sops

**Shell:**
- `modules/home/zsh.nix`: Zsh through antidote — plugins, powerlevel10k, history, fzf, zoxide, eza
- `modules/home/zsh-abbr.nix`: Zsh abbreviations — git, Nix, file system, global pipe shortcuts

**Development Tools:**
- `modules/home/dev-tools/languages.nix`: ast-grep, tree-sitter, matlab grammar, `sgconfig.yml`
- `modules/home/dev-tools/mise.nix`: mise-en-place for node/pnpm/bun runtimes + npm global tools
- `modules/home/dev-tools/navi.nix`: navi CLI cheatsheets with fzf integration

**Agents:**
- `modules/home/agents/pi.nix`: pi coding agent — full option tree for settings, MCP, search, permissions
- `modules/home/agents/hermes.nix`: hermes-agent — config renderer, workspace docs, systemd gateway service
- `modules/home/agents/bifrost/default.nix`: Bifrost MCP gateway — systemd service with envsubst config
- `modules/home/agents/tools.nix`: Agent CLI tools — tokf derivation, codebase-memory-mcp

**Secrets (sops-encrypted):**
- `secrets/zsh-secrets.env`: Shell secrets decrypted to `~/.secrets/zsh-secrets.env`
- `secrets/pi-secrets.yaml`: Pi telegram bot token

**Overlay:**
- `flake.nix` (lines 57-59): `tokf` package overlay wired into pkgs

## Naming Conventions

**Files:**
- Nix modules: Lowercase, kebab-case, `.nix` extension — `zsh-abbr.nix`, `languages.nix`
- Config files: Standard names — `config.json`, `sgconfig.yml`, `.sops.yaml`
- Documentation: Uppercase — `ARCHITECTURE.md`, `STRUCTURE.md`, `README.md`

**Directories:**
- Module groupings: Lowercase, kebab-case — `dev-tools/`, `home/`
- Host directories: Lowercase — `arch/`
- Submodule directories: Same as module name — `bifrost/` contains `default.nix`

## Module Structure Pattern

Each module group directory follows:

```
<group>/default.nix     # imports all sub-modules in the group
<group>/<module>.nix    # single-concern module with options + config
```

No module group is deeper than two levels. Every `default.nix` is purely an `imports` list — no options or config live there.

## Where to Add New Code

**New Nix package:** `pkgs/<package-name>/default.nix` — add to the overlay in `flake.nix`

**New feature module (single file):** `modules/home/<module-name>.nix` — add import to `modules/default.nix`

**New feature module (multi-file group):** `modules/home/<group-name>/` with `default.nix` importing sub-modules

**New dev tool:** `modules/home/dev-tools/` — add file and import in `dev-tools/default.nix`

**New agent:** `modules/home/agents/<agent-name>.nix` — add import to `agents/default.nix`
For multi-file agents: `modules/home/agents/<agent-name>/` with `default.nix`

**New host:** `hosts/<hostname>/home.nix` — add `homeConfigurations.<hostname>` in `flake.nix`

**New secret:** `secrets/<name>.<ext>` — reference in `modules/home/sops.nix` with sops path

**Pinned flake input:** Add to `inputs` in `flake.nix`, pass via `extraSpecialArgs`

## Tests

This project has no test suite. All changes are validated by building with `nh home switch` or `home-manager switch --flake .#saurabhj`.
