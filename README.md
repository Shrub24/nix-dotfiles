# saurabhj's Nix Configuration

Dendritic home-manager configuration managed via flakes.

## Architecture

```
.
├── flake.nix              # Entry point — flake-parts modular outputs
├── flake.lock
├── .envrc                 # use flake . --impure
├── README.md
├── home/
│   ├── default.nix        # Home-manager entry — imports modules
│   └── modules/
│       ├── core.nix       # Username, home dir, state version
│       ├── nix.nix        # Nix settings, Lix, GC policy, nix tools
│       ├── packages.nix   # General packages (nh, nil, linters, etc.)
│       └── direnv.nix     # Direnv + nix-direnv config
└── nixos/                 # Future: NixOS configurations
```

**Dendritic pattern**: Small, focused modules each owning one concern. Easy to add/remove/reorganize as the config grows toward a shared nixos+home-manager monoflake.

## Core Technologies

| Technology | Purpose |
|---|---|
| **Lix** | Nix distro — faster, better diagnostics |
| **flake-parts** | Modular flake composition |
| **nix-direnv** | Automatic flake dev shells on `cd` |
| **nh** | CLI for `home-manager` operations (`nh home switch`) |
| **nil** | Nix language server |
| **nixpkgs-fmt** | Canonical Nix formatter |
| **statix / deadnix** | Nix linter + dead code finder |
| **nix-output-monitor** | Human-readable build output |
| **comma** (`,`) | Run any package ephemerally: `, curl` |
| **manix** | Search nixpkgs docs from CLI |
| **nix-melt** | Visualize dependency trees |
| **nix-your-shell** | Nix-aware shell integration |
| **nix-index** | `nix-locate` + command-not-found |

## Commands

```bash
# Build and switch (recommended — uses nh)
nh home switch

# Apply without nh
home-manager switch --flake .#saurabhj

# Format all nix files
nix fmt

# Enter dev shell (with linters, formatter)
nix develop

# Build only
nh home build

# Run ephemerally (comma)
, curl https://example.com
,b top
, btop

# Search nix documentation
manix <topic>

# GC (automatic weekly; manual)
nix store gc --delete-older-than 30d
```

## GC Policy

- Automatic: **weekly**
- Retains: last **30 days** of generations
- Store optimisation: **auto-optimise-store** enabled

## Adding New Modules

1. Create `home/modules/<name>.nix`
2. Add `./modules/<name>.nix` to the `imports` list in `home/default.nix`
3. Run `nh home switch`

## Future

- [ ] NixOS configurations under `nixos/`
- [ ] Shared modules between nixos/ and home/
- [ ] Secrets management (sops-nix / agenix)
- [ ] CI with pre-commit hooks for nix linting
