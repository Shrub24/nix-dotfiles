## Why

The user environment needs Surge as a keyboard-driven download manager. Upstream provides a Nix flake, but release 0.11.2 incorrectly reports package version 0.8.5, so the integration must preserve correct release provenance.

## What Changes

- Pin the upstream Surge flake at release 0.11.2 with its nixpkgs input following this project.
- Apply a minimal package override so `surge --version` reports 0.11.2.
- Install Surge with the existing Home Manager development-tool set.
- Do not enable Surge's network-listening server or system service.

## Capabilities

### New Capabilities

- `surge-download-manager`: Provides the pinned Surge TUI/CLI package with correct version metadata and no implicit daemon.

### Modified Capabilities

None.

## Impact

- `flake.nix` and `flake.lock`: new pinned upstream input.
- `pkgs/surge/default.nix`: minimal correction around the upstream flake package.
- `modules/home/dev-tools/default.nix`: user package installation.
- No ports, services, tokens, or secrets are introduced.
