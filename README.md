# saurabhj's Nix Configuration

Dual-layer flake configuration managed via flakes — system-manager for daemon/root concerns, home-manager for user-scoped concerns.

## Architecture

```
.
├── flake.nix               # Entry point — flake-parts modular outputs
│                           #   systemConfigs.arch (system-manager)
│                           #   homeConfigurations.saurabhj (home-manager)
├── flake.lock
├── .envrc                  # use flake . --impure
├── README.md
├── hosts/
│   └── arch/
│       ├── system.nix      # System-manager entry — imports ../../modules/system
│       └── home.nix        # Home-manager entry — imports ../../modules/home
├── modules/
│   ├── system/
│   │   ├── default.nix     # System module aggregator
│   │   ├── nix.nix         # Daemon Nix settings (substituters, trusted keys, experimental features)
│   │   └── nixbuild.nix    # nixbuild.net SSH config + daemon env file
│   └── home/
│       ├── default.nix     # Home module aggregator
│       ├── core.nix        # Username, home dir, state version
│       ├── nix.nix         # User-scoped Nix CLI tools, programs, unfree predicate
│       ├── sops.nix        # User-scoped sops-nix secrets (API keys, tokens)
│       ├── packages.nix    # General packages
│       └── direnv.nix      # Direnv + nix-direnv config
└── pkgs/                   # Local package derivations
    ├── snip/
    ├── nix-search-tv-fzf/
    ├── iii-engine/
    ├── agentmemory/
    ├── xberg-cli/
    └── litellm/
```

**Dendritic pattern**: Small, focused modules each owning one concern. System modules own daemon/root configuration; home modules own user-scoped concerns.

## Core Technologies

| Technology | Purpose |
|---|---|
| **system-manager** | Manage daemon-level Nix settings and system configuration on non-NixOS |
| **home-manager** | Manage user environment (packages, shell, services, secrets) |
| **flake-parts** | Modular flake composition |
| **nix-direnv** | Automatic flake dev shells on `cd` |
| **nh** | CLI for both layers (`nh home switch`, `nh os switch`) |
| **sops-nix** | User-scoped secret management (API keys, tokens) |
| **nixfmt** | Canonical Nix formatter |
| **statix / deadnix** | Nix linter + dead code finder |
| **nix-output-monitor** | Human-readable build output |
| **comma** (`,`) | Run any package ephemerally: `, curl` |
| **manix** | Search nixpkgs docs from CLI |
| **nix-your-shell** | Nix-aware shell integration |
| **nix-index** | `nix-locate` + command-not-found |

## Commands

```bash
# Build and switch home-manager (recommended — uses nh)
nh home switch

# Build and switch system-manager (recommended — uses nh)
nh os switch

# Apply home-manager without nh
home-manager switch --flake .#saurabhj

# Apply system-manager without nh
system-manager switch --flake .#arch

# Format all nix files
nix fmt

# Enter dev shell (with linters, formatter)
nix develop

# Build only (home)
nh home build

# Build only (system)
nh os build

# Run ephemerally (comma)
, curl https://example.com

# Search nix documentation
manix <topic>

# GC (automatic weekly; manual)
nix store gc --delete-older-than 30d
```

## GC Policy

- Automatic: **weekly** (via home-manager user timer `nh-clean`)
- Retains: last **7 days** of generations
- Store optimisation: **auto-optimise-store** enabled

## Adding New Home Modules

1. Create `modules/home/<name>.nix`
2. Add `./<name>.nix` to the `imports` list in `modules/home/default.nix`
3. Run `nh home switch`

## Adding New System Modules

1. Create `modules/system/<name>.nix`
2. Add `./<name>.nix` to the `imports` list in `modules/system/default.nix`
3. Run `nh os switch`

## Ownership Boundaries

- **System layer** (`modules/system/`): daemon configuration, system-level secrets, systemd services (root scope)
- **Home layer** (`modules/home/`): user packages, programs, shell config, user-scoped secrets, user timers (user scope)

## Future

- [ ] NixOS configurations under `nixos/`
- [ ] Shared modules between nixos/ and system-manager/
