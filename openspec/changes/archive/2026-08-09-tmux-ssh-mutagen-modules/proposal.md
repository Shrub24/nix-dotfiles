## Why

Home Manager manages the user's shell, editor agents, and dev tools, but tmux session config, SSH client config, and remote-dev tooling (mutagen) are still local state. Bringing these under Home Manager makes them reproducible, version-tracked, and consistent across rebuilds.

## What Changes

- Create `modules/home/tmux.nix` with native `programs.tmux.*` for general terminal session management.
- Create `modules/home/remote/` concern group with:
  - `remote/ssh.nix` — native `programs.ssh.*` for SSH client defaults; no `known_hosts`, no `authorized_keys`, no private key material.
  - `remote/mutagen.nix` — thin wrapper installing `pkgs.mutagen` (already in nixpkgs). Room for future aliases/env but package-only for now.
- Import both from `modules/default.nix`.
- Machine-specific SSH host blocks and identity-file paths go in `hosts/arch/home.nix`.

## Capabilities

### New Capabilities

- `tmux`: Declarative tmux config via `programs.tmux.*` (enable, extraConfig, plugins, sensible defaults for persistent remote sessions).
- `ssh-client`: Declarative SSH client config via `programs.ssh.*` (global settings, generic defaults, no host-specific blocks in the module).
- `mutagen`: Install `pkgs.mutagen` for file-sync remote-dev workflow; thin module with room to grow.

### Modified Capabilities

None.

## Impact

- `modules/default.nix` gets two new imports (`./home/tmux.nix`, `./home/remote`).
- `hosts/arch/home.nix` may later gain SSH host aliases / identity key references.
- `pkgs.mutagen` used from nixpkgs — no custom derivation needed.
