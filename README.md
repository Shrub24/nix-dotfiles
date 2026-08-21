# saurabhj's Nix Configuration

Dendritic flake: home-manager for the user environment, system-manager for
daemon/root concerns on the non-NixOS host, and a native NixOS configuration
for the bare-metal target (`nixosConfigurations.shrub`).

## Requirements

- Flakes-enabled Nix (`nix-command` + `flakes` experimental features)
- [direnv](https://direnv.net) — optional, for automatic dev-shell entry

## Setup

```bash
git clone git@github.com:Shrub24/nix-dotfiles.git ~/.dotfiles/nix
cd ~/.dotfiles/nix
nix develop          # or: direnv allow (uses .envrc — `use flake . --impure`)
```

## Usage

```bash
# Switch the user environment (home-manager)
nh home switch .#saurabhj

# Switch system configuration (system-manager, non-NixOS host)
system-manager switch --flake .#arch

# Switch the NixOS configuration (bare-metal host)
nh os switch .#shrub

# Validate: format, lint, and evaluate all host configurations (same as CI)
nix flake check --no-build --no-write-lock-file

# Format all maintained files (Nix, Markdown, TOML, YAML, JSON)
nix fmt

# Install git hooks — pre-commit fmt/lint, pre-push flake check
nix develop -c lefthook install

# Garbage collect (automatic weekly; manual run)
nh clean all --keep-since 7d
```

## Architecture

Setup and operator commands live here; the durable design — directory layout,
module composition, data flow, and ownership boundaries — is in
[`ARCHITECTURE.md`](ARCHITECTURE.md).

Secrets are sops-nix encrypted; switching requires the corresponding age keys
(see the secrets section of `ARCHITECTURE.md`).
