## Context

The user's SSH client config, tmux config, and mutagen tooling are not yet managed by Home Manager. All three are user-level concerns that fit the existing module pattern in this repo. The agreed layout places tmux as a top-level module and SSH/mutagen under a `remote/` concern group.

## Goals / Non-Goals

**Goals:**
- Declarative tmux config via native `programs.tmux.*`.
- Declarative SSH client config via native `programs.ssh.*`.
- Install `pkgs.mutagen` via a thin module that can grow later.
- Follow the repo's existing module patterns (one-file modules for single concerns, subdirectory groups for related concerns).

**Non-Goals:**
- Managing `known_hosts`, `authorized_keys`, or private key material.
- Managing SSH host-specific blocks in the shared module (those go in the host config).
- Any custom Nix derivations (mutagen is already in nixpkgs).
- Any custom option schemas (all three use native Home Manager or standard packages).

## Decisions

- **tmux as top-level module, not under remote/**: tmux is a general terminal session tool, not remote-specific. Placing it under `remote/` would misrepresent its scope.
- **remote/ as concern group for SSH + mutagen**: Both are semantically about remote access / remote dev. This matches the repo's pattern of grouped directories for related concerns (e.g., `dev-tools/`, `agents/`).
- **Thin mutagen wrapper**: Package install only for now. Room for future aliases/env without over-engineering upfront.
- **SSH host blocks in host config**: The shared module holds generic client defaults only. Machine-specific host names, identity files, and Tailscale endpoints go in `hosts/arch/home.nix`.

## Risks / Trade-offs

- [Low] SSH client defaults in the shared module may need refinement as more machines are added. Mitigation: start minimal and iterate.
- [Low] Thin mutagen.nix may need restructuring if more config is added. Mitigation: the pattern is clear — add `home.packages` first, then options as needs arise.
