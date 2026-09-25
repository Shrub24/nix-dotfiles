# Proposal — Migrate `/home` to the data disk

## Why

The root NVMe is 84% full and `/home` accounts for ~117G of it, while the
650G data disk sits at 43%. The home directory also lives in snapper's
`snapshots` path, so high-churn state — six indices (~34G), `~/.cache`
(56G), container images — lands in every home snapshot as pure bloat. The
same split fixes both: move the home subvolume to the data disk, and carry
nested subvolumes for churn paths so snapshots of the home skip them. A
side effect lands the uv venv fix: cache and projects then share one
filesystem, so `UV_LINK_MODE=clone` reflinks instead of copying (~59G of
duplicate venvs collapse).

## What Changes

- **BREAKING (one-time, operator-run)**: `/home` moves from the root disk's
  `@home` to a new `@home` on the data disk; `/mnt/LinuxData` becomes
  `/data` mounted at a dedicated `@data` subvolume. Runbook:
  `docs/runbooks/migrate-home-to-data-disk.md`.
- The seven user symlinks into `/mnt/LinuxData` (`Documents`, `Projects`,
  `Music`, …) become real directories under `~/`; `Projects` and `Music`
  land as nested subvolumes later only if their churn profile demands it.
- Nested subvolumes under the new home for churn paths: `~/.cache`,
  `~/.local/{share,state}`, `~/.local/share/containers`, `~/.npm`,
  `~/.bun`, `~/go`, `~/.cargo`, `~/.rustup`, `~/.nuget`, `~/.gradle`,
  `~/.mozilla`; `chattr +C` on containers and browser profiles.
- A typed storage-topology SSOT (`storage.dataDisk`) projected into both
  classes: system-manager gets mount units + an idempotent skeleton oneshot
  - snapper configs via `environment.etc`; NixOS gets `fileSystems` from
    the same SSOT (closing the gap where `/home` is undeclared in
    `_hardware.nix`).
- **NixOS prewiring, stated now even where Arch cannot realize it**: a
  `_disko.nix` capturing both disks' target partition/subvolume layout as a
  disko config (written but unimported until install day), and declarative
  snapper timers/retention on the NixOS side so `snapper-snapshots` lands
  fully declarative.
- `modules/agents/pi.nix`'s eleven `/mnt/LinuxData/Projects` paths become
  home-relative once `~/Projects` exists.

## Capabilities

### New Capabilities

- `storage-topology` — the host's disk/subvolume/mount SSOT: one typed
  declaration projected into both privilege classes; churn-path subvolume
  set; nodatacow set; system-manager mount units and skeleton oneshot;
  NixOS `fileSystems` and disko capture.

### Modified Capabilities

- None. `filesystem-bootstrap` governs mutable _seeds inside_ configured
  paths and stays untouched; this change owns which paths are mounted and
  which are subvolumes.

## Impact

- Pros: root disk drops from 253G to ~136G used; home snapshots stop
  absorbing indices/caches; one declarative fact-base for install day.
- Risks: a bad fstab edit is boot-affecting — mitigated by the untouched
  root-disk `@home` rollback and the TTY cutover procedure.
- Non-goals: impermanence (future), moving the root disk's other subvols,
  deleting the old `@home` (kept as rollback), any change to snapper's
  `root` config.
