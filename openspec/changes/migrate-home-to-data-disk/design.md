# Design

## Context

The desktop's home directory lives on the root NVMe's `@home` subvolume
(nvme0n1p5, 84% full). Seven user directories are symlinks into
`/mnt/LinuxData`, a 650G btrfs disk mounted at its **top level**
(subvolid 5) — no subvolume container, with `.snapshots/` and loose dirs
sitting at the root of the filesystem. Snapper runs three configs (`root`,
`home`, `data`), all managed imperatively.

`~/.cache` is already a nested subvolume (subvol ID 5193), so the largest
churn source is already out of home snapshots — but it lives on the root
disk, and its separation is invisible to any declaration. `uv` cannot
hardlink across the two filesystems (device 83 vs 63), so eleven ~5.4G
research venvs are full copies; `UV_LINK_MODE=clone` (reflink) already
landed in `modules/shell/default.nix` and becomes effective once both sides
share a filesystem.

system-manager's module surface is `environment`, `etc`, `systemd`,
`tmpfiles` — no `fileSystems`, no mounts. system-manager's own docs list
`fileSystems` as a NixOS difference. Home Manager is user-scope and cannot
mount anything.

## Goals / Non-Goals

**Goals:**

- One typed declaration (`storage.dataDisk`) owns the data disk's facts;
  both classes project it.
- `/home` and `/data` are declaratively mounted on Arch (systemd mount
  units) and declaratively declared on NixOS (`fileSystems`), from the same
  declaration.
- The churn subvolume set is explicit and extendable — new tools' state
  paths join the set instead of silently landing in snapshot paths.
- NixOS target state is prewired: disko config for both disks, declarative
  snapper timers/retention, `fileSystems` including the currently-undeclared
  `/home`.
- The operator migration (runbook) and the declarative skeleton converge on
  the same subvolume set, so either can run first.

**Non-Goals:**

- Impermanence (explicitly deferred by the user).
- Managing the root disk's boot-critical mounts (`/`, `/nix`, `/boot`,
  `/var/*`) — they stay in fstab; dracut and the initramfs own that path.
- Deleting the root disk's old `@home` (rollback), resizing partitions, or
  any destructive btrfs operation.
- Moving `OneDrive/` / `.onedriver/` off the data-disk top level.

## Decisions

### D1 — Mount units, not fstab, for the data disk (system-manager)

systemd's fstab generator defers to an existing unit file, so declaring
`.mount` units for `/home` and `/data` and removing those two fstab lines
is equivalent at boot and evaluation-visible. fstab keeps only
initramfs-coupled mounts. The declaration renders the units' `What=` (UUID

- subvol option), `Where=`, `Type=btrfs`, and mount options.

_Rejected_: `environment.etc."fstab"` — it would make the whole file a
store symlink (including the lines dracut consumes at image build time)
for the benefit of two lines the generator does not need.

### D2 — Idempotent skeleton as a oneshot with Conditions

`storage-skeleton.service` (systemd system unit, `Type=oneshot`,
`ConditionPathExists=!@home`) creates `@home`/`@data` and each churn
subvolume only when absent (`btrfs subvolume create` fails on an existing
path — acceptable: the unit is guarded per-path, and re-runs converge).
`chattr +C` is applied at creation on an empty subvolume. The unit runs
`Before=home.mount` so first-boot ordering is correct; on the already-
migrated host it is a no-op that keeps the declaration honest.

_Rejected_: relying on the runbook alone — the declaration would name
subvols nothing creates on a fresh host.

### D3 — Churn set is data, not mechanism

`homeChurn` is a list of home-relative paths in the declaration; the
skeleton iterates it and the snapshot contract reads it. Coarse
subvolumes over per-tool splits: `~/.local/share` as one subvol loses
snapshot coverage for `fonts`/`wallpapers`/`nvim` state (regenerable or
Nix-owned) but keeps working when a new index tool appears — the two
existing misses (`aube`, `cortexkit`) prove per-tool lists rot.

### D4 — disko written now, imported at install day

`_disko.nix` captures both disks' target layout as a disko config. It is
not imported into any host composition yet (disko would try to manage a
live system), but it must evaluate and render the same subvolume set the
declaration names — checked by an eval assertion. Install-day changes
(`nixos-dual-boot-install`, `add-spectre-host`) consume it.

### D5 — Snapper ownership splits by class

NixOS: `services.snapper.configs` + `services.snapper.timers` (native
module) declaratively from the runbook-captured configs — retention values
ported verbatim as the imperative truth. Arch: configs via
`environment.etc."snapper/configs/..."`; timers stay with the pacman
package. The `data` config's `SUBVOLUME` follows the new mountpoint.

## Migration / Compatibility

Runbook: `docs/runbooks/migrate-home-to-data-disk.md` (operator-run, fish).
Ordering between runbook and code is flexible — the runbook's Phase 1 and
the skeleton create the same subvols — but the fstab→mount-unit swap and
`pi.nix`'s path rewrites must follow the cutover, not precede it.
Rollback is reverting two fstab lines; the root disk's `@home` is
untouched by everything here.

`modules/agents/pi.nix` moves its eleven `/mnt/LinuxData/Projects` paths
to `home.homeDirectory`-derived ones only after `~/Projects` is a real
directory (Phase 3).

## Verification

- `nix flake check --no-build` covers evaluation of all three host outputs.
- Eval assertions: home/data mount units render with the declared UUID;
  `fileSystems."/home"` exists on the NixOS side; the disko config renders
  the declaration's subvol set; skeleton unit iterates exactly the churn
  set.
- Live checks land in the runbook's Phase 3 (`findmnt`, `btrfs subvolume
list`, `snapper -c home list`).
