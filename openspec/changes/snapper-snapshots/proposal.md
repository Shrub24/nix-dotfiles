# Proposal — Snapper snapshots on the NixOS hosts

## Why

`nixos-system-services` deferred Snapper btrfs snapshot configs because snapshots
of `/` have to live outside the subvolume they capture: the layout must reserve a
`@snapshots` subvolume, and reserving it is an install-time decision. Until that
layout exists, `services.btrfs.autoScrub` is the only btrfs protection in place —
it detects bit rot, but it cannot undo a bad switch or update.

The deferred item outlived the change that deferred it, so it lives here as its
own tracking item.

## What Changes

- Reserve and mount `@snapshots` in each NixOS host's filesystem layout — the
  desktop's bare-metal install and the laptop's first install.
- Declare `services.snapper.configs` over the subvolumes that exist on each host.
  The desktop's NixOS module already carries them
  (`modules/hosts/arch/_nixos.nix`); the laptop has none.
- Verify `snapper list` and one deliberate rollback per host.

The install-day layout stays owned by the install changes
(`nixos-dual-boot-install`, `add-spectre-host`); this change owns the snapshots
that layout exists for. No spec deltas: this is deployment layout, not a
contract.
