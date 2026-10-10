# Proposal

## Why

Nix already owns most of Legion's system configuration, but undeclared root state survives indefinitely. A resettable root would make those dependencies explicit while leaving application data in the persistent home untouched.

This is a **tentative preliminary plan**, not approval to implement or reset anything. Disk growth is the next operation; it does not depend on this change, and this change does not require disk growth. The ordering is operational, not a storage prerequisite.

## What Changes

- Provisionally prefer Preservation for Legion's system-state persistence, subject to tests against the repository's pinned nixpkgs. Impermanence and retaining persistent root remain alternatives.
- Prepare persistent system state on the encrypted root filesystem, with a conservative initial manifest and explicit early-boot requirements.
- Resolve password provisioning, secret bootstrap, machine identity, service-owned state and automatic-timezone behaviour before enabling a reset.
- Rehearse a systemd-initrd Btrfs root reset, with the reset mechanism separate from persistence mounts.
- Preserve `/nix`, home, data, logs and other independently mounted storage. Existing home subvolumes remain intentional snapshot boundaries, not deletion instructions.
- **BREAKING, only if later approved:** undeclared state in the root subvolume will disappear at reset-enabled boot. Existing data must be migrated and backed up first.
- Require a tested reset-disabled recovery boot and explicit approval before the first hardware reset.

## Capabilities

### New Capabilities

- `root-state-persistence`: selected system state survives root resets without changing home topology, service ownership or established host identity; reset and recovery behaviour are independently controlled.

### Modified Capabilities

None. The existing `filesystem-bootstrap` ownership contract continues to apply. This plan does not change home snapshot boundaries or activate ephemeral home.

## Impact

Potential implementation areas are Legion's host/storage modules, a selectable NixOS persistence aspect, feature-local persistence declarations, the package/input declarations, VM tests and operator documentation. The exact seam and manifest remain subject to review; no new abstraction is required merely to bridge Home Manager.

Preservation would be a new pinned input if accepted. No input, configuration, filesystem, canonical spec or deployment changes occur while saving this plan. Spectre, ephemeral home, partition growth, Arch removal and telemetry routing are out of scope.

`docs/impermanence.md` remains the path inventory, but is not yet a complete reset manifest. `design.md` preserves the research, trade-offs, known blockers and unresolved choices. All implementation tasks remain unchecked.
