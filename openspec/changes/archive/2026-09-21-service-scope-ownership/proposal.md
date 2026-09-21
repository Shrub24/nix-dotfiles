# Proposal — service scope ownership

## Why

Two long-running pieces of work are owned by the wrong layer, and one of them is
dead code.

**Surge's daemon.** The canonical spec pins the daemon to a NixOS-only system
unit (`flake.modules.nixos.surge`, `wantedBy = multi-user.target`, running as
root). Two problems:

- The aspect was never selected. `nixosAspects` in `modules/hosts/arch.nix` does
  not contain `surge`, so no host ever ran a Surge daemon, while
  `embeddedHmAspects` still subtracted the HM aspect — meaning the NixOS desktop
  had neither the package nor the daemon. The spec described behaviour that did
  not exist.
- The shape is wrong for the job. Surge writes the files you then open, so the
  account running it should own the directory it fills. A root-run daemon writing
  into a user's Downloads owns those files as root; worse, `surge server start`
  defaults its output directory to the working directory, which for a system unit
  is `/`.

**Garbage collection.** The only GC timer is the Home Manager one, which runs
`nh clean user` — user generations only. The system profile is never collected
on either host: on NixOS nothing sets `programs.nh.clean`, and system-manager
offers neither `nix.gc` nor an nh module, so the Arch system profile has no
declarative collector at all.

## What Changes

- **Surge runs as a user service on both hosts.** The HOME MANAGER aspect gains
  `systemd.user.services.surge` (`surge server start --port 1700 --output ~/Downloads`), and `flake.modules.nixos.surge` is deleted. The daemon then
  exists on every host that selects the aspect — including the NixOS desktop,
  which previously had nothing — with one definition instead of two.
- **GC has exactly one owner per host scope.** On NixOS the system-scoped
  `programs.nh.clean` runs `nh clean all` as root (which covers user generations
  too); on the non-NixOS host, where nothing system-scoped can collect the store,
  the existing user timer (`nh clean user`) stays. The Home Manager timer is
  gated on `targets.genericLinux.enable` so the same aspect is correct in both
  evaluations.
- **Documentation follows**: `ARCHITECTURE.md` lists the surge daemon among the
  active user services, drops it from the system-owned aspect list, and records
  the single-owner GC rule.

## Impact

- Affected specs: `surge-download-manager` (one requirement modified, one
  removed).
- Affected code: `modules/surge.nix`, `modules/nix.nix`,
  `modules/hosts/arch.nix`, `ARCHITECTURE.md`.
- Not affected: package provenance (still `pkgs.surge-downloader` from nixpkgs),
  the Arch host's lack of a system-side GC timer (accepted), container storage.
