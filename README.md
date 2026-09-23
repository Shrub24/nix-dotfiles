# saurabhj's Nix Configuration

Dendritic flake: home-manager for the user environment, system-manager for
daemon/root concerns on the non-NixOS host, and a native NixOS configuration
for the bare-metal target (`nixosConfigurations.legion`).

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
nh home switch -c saurabhj

# Switch system configuration (system-manager, non-NixOS host)
system-manager switch --flake .#legion

# Switch the NixOS configuration (bare-metal desktop host)
nh os switch .#legion

# Switch the NixOS configuration (portable laptop host)
nh os switch .#spectre

# Validate: format, lint, and evaluate all host configurations (same as CI)
nix flake check --no-build --no-write-lock-file

# Format all maintained files (Nix, Markdown, TOML, YAML, JSON)
nix fmt

# Install git hooks — pre-commit fmt/lint, pre-push flake check
nix develop -c lefthook install

# Garbage collect (automatic weekly; manual run)
nh clean all --keep-since 7d
```

## Flake inputs

`flake.nix` is **generated** by [flake-file](https://flake-file.denful.dev) from
input declarations in the module tree — never edit it by hand. Declare an input
next to the feature that consumes it, or in `modules/flake/inputs.nix` when it
belongs to the flake plumbing or the package layer. Regenerate and verify:

```bash
nix run .#write-flake                              # rewrite flake.nix + flake.lock
nix flake check --no-build --no-write-lock-file    # includes the in-sync check
```

[`Shrub24/nix-fleet`](https://github.com/Shrub24/nix-fleet) is the fleet's
platform repository. It owns the pins both repositories share — `nixpkgs`,
`flake-parts`, `import-tree`, `treefmt-nix` and `flake-file` are _follows_ onto
it, so a single nix-fleet update moves them together — and it owns the canonical
inventory: what each fleet machine _is_ (target system, tailnet hostname, SSH
host key). `modules/policy/fleet.nix` imports its contract, so this repository
declares only what it decides — the login user, the account it configures, which
builders it schedules. Everything else here — home-manager, system-manager,
Noctalia, agent and desktop tooling — is this repository's own input and updates
independently.

Nested `nixpkgs` follows are declared next to the input they redirect; nothing
infers them. An upstream that builds against its own pin declares none:
`hermes-agent` keeps its own.

To test against a coordinated nix-fleet change, point the input at a local
checkout without touching the committed URL:

```bash
just fleet-check                       # NIX_FLEET_DIR, default ../nix-fleet
nix flake check --no-build --override-input nix-fleet path:../nix-fleet
```

## Architecture

Setup and operator commands live here; the durable design — directory layout,
module composition, data flow, and ownership boundaries — is in
[`ARCHITECTURE.md`](ARCHITECTURE.md). The rules that no tool enforces —
commenting, validation, module and aspect style — are in
[`CONVENTIONS.md`](CONVENTIONS.md).

Secrets are sops-nix encrypted; switching requires the corresponding age keys
(see the secrets section of `ARCHITECTURE.md`).
