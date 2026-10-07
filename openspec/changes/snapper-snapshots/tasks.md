# Tasks — Snapper snapshots on the NixOS hosts

## Desktop (`legion`)

- [x] Reserve `@snapshots` in the install-time btrfs layout and mount it at
      `/.snapshots` (`nixos-dual-boot-install` owns that install).

  - done: `modules/hosts/legion/_disko.nix` declares `@snapshots` at
    `/.snapshots`, and `docs/runbooks/provision-legion.md` §6 creates and mounts
    it on the installed disk.

- [x] Confirm `services.snapper.configs` in `modules/hosts/legion/_nixos.nix`
      names subvolumes that actually exist on the installed disk.

  - done: the module declares `configs.root` and `configs.home`, and the
    installed root carries `@` and `@home`.

- [ ] `snapper list` shows a snapshot after a switch, and one rollback is
      performed deliberately rather than discovered in an emergency.

  - reason: still open — a runtime verification on the booted desktop; no
    snapshot or deliberate rollback has been exercised or recorded yet.

## Laptop (`spectre`)

- [x] Add `@snapshots` to the subvolume set (`add-spectre-host` owns that
      install).

  - done: `modules/hosts/spectre/_disko.nix` declares `@snapshots` at
    `/.snapshots`; the installed disk was created from that declaration.

- [ ] Declare `services.snapper.configs` for the laptop's subvolumes.

  - reason: still open — `modules/hosts/spectre/_nixos.nix` declares no
    `services.snapper.configs` yet.

- [ ] Same verification: a listed snapshot and one deliberate rollback.

  - reason: still open — blocked on the laptop's snapper configs above.

## Both hosts

- [x] Keep `services.btrfs.autoScrub` enabled: snapshots answer "undo this
      change", scrubbing answers "is the data still intact", and neither replaces
      the other.

  - done: the shared `foundation` boot aspect enables `services.btrfs.autoScrub`
    for both hosts (`modules/foundation/boot.nix`).
