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

The mount and snapshot facts belong to one host class: NixOS declares
`fileSystems`, disko renders the install target's mounts, and Home Manager is
user-scope and cannot mount anything.

## Goals / Non-Goals

**Goals:**

- One typed declaration (`storage.dataDisk`) owns the data disk's facts;
  every consumer projects it.
- `/home` and `/data` are declared on the NixOS target (`fileSystems`)
  from the same declaration.
- The churn subvolume set is explicit and extendable — new tools' state
  paths join the set instead of silently landing in snapshot paths.
- NixOS target state is prewired: the install-target disko declaration,
  declarative snapper timers/retention, `fileSystems` including the
  currently-undeclared `/home`.
- The operator migration (runbook) and the install-day disko layout
  converge on the same subvolume set, so either can run first.

**Non-Goals:**

- Impermanence (explicitly deferred by the user).
- Managing the root disk's boot-critical mounts (`/`, `/nix`, `/boot`,
  `/var/*`) — they stay in fstab; dracut and the initramfs own that path.
- Deleting the root disk's old `@home` (rollback), resizing partitions, or
  any destructive btrfs operation.
- Moving `OneDrive/` / `.onedriver/` off the data-disk top level.

## Decisions

### D1 — the data disk's mounts are projected by `fileSystems`

The data disk is declared once in `storage.dataDisk` and projected into the
NixOS `fileSystems` entries for `/home` and `/data`. There is no second host
to project it into.

_Rejected_: systemd `.mount` units plus `environment.etc."fstab"` — both are
evaluation-visible ways to restate mounts that `fileSystems` already owns.

### D2 — `nodatacow` is realized where the path is created

`chattr +C` has no declarative owner: the nodatacow paths
are nested subvolumes inside the home mount, so `nodatacow` is not
available as a per-subvolume mount option, and disko cannot set an
attribute. The attribute was applied by the imperative migration; the
requirement survives in the declaration for the next reorganization of the
data disk.

_Rejected_: a per-path creation oneshot — the only mechanism the format
offers, and it would have to run `Before=home.mount` on a host whose
subvolumes install day creates anyway.

### D3 — Churn set is data, not mechanism

`homeChurn` is a list of home-relative paths in the declaration; the
snapshot contract reads it. Coarse
subvolumes over per-tool splits: `~/.local/share` as one subvol loses
snapshot coverage for `fonts`/`wallpapers`/`nvim` state (regenerable or
Nix-owned) but keeps working when a new index tool appears — the two
existing misses (`aube`, `cortexkit`) prove per-tool lists rot.

### D4 — disko describes the install target only

`_disko.nix` captures the install target's partition and subvolume layout and
is imported by the NixOS host composition, so the installed root's mounts come
from one declaration. The data disk stays outside it: it already holds the
user's home and is never repartitioned, and a disko declaration naming it
would invite exactly that.

### D5 — Snapper covers root and home, not the residual data mount

NixOS: `services.snapper.configs` + `services.snapper.timers` (native
module) declaratively from the runbook-captured root/home configs — retention
values ported verbatim as the imperative truth. `/data` remains mounted but has
no Snapper config: it holds opaque rescue images plus package/cache residue,
not user data whose snapshots provide value.

## Migration / Compatibility

Runbook: `docs/runbooks/migrate-home-to-data-disk.md` (operator-run, fish).
Ordering between runbook and code is flexible — the runbook's Phase 1 and the
disko layout create the same subvols — but `pi.nix`'s path rewrites must
follow the mount change, not precede it. Rollback is reverting two fstab
lines; the root disk's `@home` is untouched by everything here.

`modules/agents/pi.nix` moves its eleven `/mnt/LinuxData/Projects` paths
to `home.homeDirectory`-derived ones only after `~/Projects` is a real
directory (Phase 3).

## Verification

- `nix flake check --no-build` covers evaluation of both host outputs.
- Eval assertions: `fileSystems."/home"` exists on the NixOS side and
  derives from the declaration; the install-target disko declaration
  renders the subvolume set the installed root carries.
- Live checks land in the runbook's Phase 3 (`findmnt`, `btrfs subvolume
list`, `snapper -c home list`).
