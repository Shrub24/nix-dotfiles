# Tasks — Snapper snapshots on the NixOS hosts

## Desktop (`shrub`)

- [ ] Reserve `@snapshots` in the install-time btrfs layout and mount it at
  `/.snapshots` (`nixos-dual-boot-install` owns that install).
- [ ] Confirm `services.snapper.configs` in `modules/hosts/arch/_nixos.nix`
  names subvolumes that actually exist on the installed disk.
- [ ] `snapper list` shows a snapshot after a switch, and one rollback is
  performed deliberately rather than discovered in an emergency.

## Laptop (`spectre`)

- [ ] Add `@snapshots` to the subvolume set and declare
  `services.snapper.configs` for the laptop's subvolumes
  (`add-spectre-host` owns that install).
- [ ] Same verification: a listed snapshot and one deliberate rollback.

## Both hosts

- [ ] Keep `services.btrfs.autoScrub` enabled: snapshots answer "undo this
  change", scrubbing answers "is the data still intact", and neither replaces
  the other.
