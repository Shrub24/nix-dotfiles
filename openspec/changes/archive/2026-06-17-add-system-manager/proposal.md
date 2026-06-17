## Why

This repository currently manages only user-scoped configuration through Home Manager, while the Nix daemon and other root-owned system configuration on the Arch host remain unmanaged. That gap makes daemon-scoped concerns like `/etc/nix/nix.conf`, root SSH settings, and daemon environment injection awkward to configure and easy to drift.

## What Changes

- Add `system-manager` to the flake so this repo can manage system-scoped configuration on the Arch host alongside existing Home Manager modules.
- Introduce a parallel `modules/system/` and `hosts/arch/system.nix` structure for declarative system-level configuration.
- Move daemon-relevant Nix configuration out of the Home Manager `modules/home/nix.nix` path into system-level configuration managed for the host.
- Establish a system-scoped path for daemon-facing nixbuild.net access configuration, including root/daemon-visible SSH and environment settings where required.
- Preserve existing user-scoped Home Manager concerns such as shell config, user services, and user secrets unless a later change explicitly promotes them.

## Capabilities

### New Capabilities
- `system-manager-foundation`: Add a system-manager flake output and module structure for declarative system-scoped configuration on the Arch host.
- `daemon-nix-config`: Manage daemon-visible Nix settings and nixbuild.net access configuration at system scope instead of user scope.

### Modified Capabilities
- None.

## Impact

- Affects `flake.nix`, `hosts/arch/`, and new `modules/system/` files.
- Refactors `modules/home/nix.nix` to retain only user-scoped Nix tooling and cleanup behavior.
- Introduces a new system-level dependency on `system-manager`.
- Changes how daemon-facing Nix and nixbuild.net configuration is declared and applied on the Arch machine.
