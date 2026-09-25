# Runbook — Migrate `/home` to the data disk

One-time migration of the desktop (`legion`, Arch) from the root NVMe
`@home` subvolume to a `@home` subvolume on the 650G data disk, with a
nested-subvolume layout that keeps high-churn paths out of snapper's home
snapshots.

Planning record: `openspec/changes/migrate-home-to-data-disk/`. All shell
snippets are **fish**.

## Before you start

- Root NVMe (`nvme0n1p5`, 311G) is 84% full — `/home` holds ~117G of it.
  Data disk (`nvme1n1p7`, 650G) has ~375G free.
- `~/.cache` (56G) is already a nested subvolume on the root disk; it is
  recreated as one on the data disk.
- The old `@home` is the rollback: nothing in this runbook deletes it. Keep
  it for a few weeks.

## Phase 1 — live, no downtime (~20 min)

```fish
set -l D /mnt/LinuxData
set -l H $D/@home/saurabhj

# 1a. @home skeleton.
#     saurabhj is a PLAIN DIR — it must be inside home snapshots.
#     Only the churn dirs beneath it are subvols (snapshots skip subvols).
sudo btrfs subvolume create $D/@home
sudo btrfs subvolume create $D/@home/.snapshots
sudo mkdir -p $H
for d in .cache .npm .bun go .cargo .rustup .nuget .gradle .mozilla
    sudo btrfs subvolume create $H/$d
end
sudo mkdir -p $H/.local
sudo btrfs subvolume create $H/.local/share
sudo btrfs subvolume create $H/.local/state
sudo btrfs subvolume create $H/.local/share/containers
sudo chattr +C $H/.local/share/containers $H/.mozilla   # overlayfs + SQLite
# NOTE: .cache stays CoW+compressed — nodatacow disables compression on 56G.

# 1b. @data (bulk). The seven symlinked user dirs are NOT moved here —
#     they become real directories under ~/ in Phase 3.
sudo btrfs subvolume create $D/@data
sudo btrfs subvolume create $D/@data/.snapshots   # must be a subvol, or snapshots recurse
sudo ls $D/.snapshots                              # confirm empty
sudo mv $D/.snapshots $D/@data/.snapshots-legacy   # if not empty, move it aside
sudo rmdir $D/.snapshots
sudo mv $D/btrfs-rescue.img $D/btrfs-root-rescue.img $D/.Trash-1000 $D/.pnpm-store $D/@data/
# OneDrive/ and .onedriver/ stay at top level for now.

# 1c. seed (117G NVMe→NVMe, ~10-15 min). No --delete on this pass.
sudo rsync -aHAXS --info=progress2 --exclude='.snapshots/' /home/ $D/@home/
```

Expect `link … failed: Invalid cross-device link (18)` warnings from the
rsync generator: bun hardlinks packages from `~/.bun/install/cache` into
every `node_modules`, and the source hardlinks cross the root disk's
boundary (`.bun` is NOT a subvolume today) while the destination side
(`.bun` inside `@home`) is a separate subvolume. The files are still
copied — `-H` preserves the links where both ends sit in the same
destination subvolume, and every warning names a file rsync fell back to
a real copy for. Nothing to fix; the count stops growing once `.bun`'s
content is through.

## Phase 2 — cutover (~5 min + reboot)

1. Log out of niri, switch to a TTY (`Ctrl+Alt+F3`), log in, `sudo -i`.
2. Delta pass:

   ```fish
   sudo rsync -aHAXS --delete --info=progress2 --exclude='.snapshots/' /home/ /mnt/LinuxData/@home/
   ```

3. Edit `/etc/fstab` — replace the `/home` line and the `/mnt/LinuxData`
   line (the `/`, `/nix`, `/boot`, `/var/*` lines stay untouched):

   ```
   UUID=47fa5ee2-addd-466b-b7fc-4e7d92968234  /home  btrfs  subvol=/@home,noatime,compress=zstd  0 0
   UUID=47fa5ee2-addd-466b-b7fc-4e7d92968234  /data  btrfs  subvol=/@data,noatime,compress=zstd  0 0
   ```

4. `reboot`.

## Phase 3 — post-boot (~10 min)

```fish
findmnt /home /data; df -h / /data        # verify both mounts

# one admin mount to reach the old top level
sudo mkdir -p /mnt/top
sudo mount -o subvolid=5 /dev/nvme1n1p7 /mnt/top

# Target state: these are real directories under @home. Do not run a
# blanket move here without checking first. A cross-subvolume `mv` is not a
# reflink operation; GNU mv may fall back to a full recursive copy.
# If any path is still a symlink, inspect it and convert that one path only
# after verifying source and destination. Projects and Music stay as real
# dirs for now while their churn is being investigated.

# data has no Snapper config: it contains rescue images and package/cache
# residue, not user data worth snapshotting. Verify home snapshots only.
sudo snapper -c home list                  # shows the new home subvol's snapshots

sudo btrfs subvolume list /mnt/top         # final topology check — paste output
```

Also capture the two remaining Snapper configs for the declarative port:

```fish
sudo cat /etc/snapper/configs/{root,home}
```

## Aftermath

- `UV_LINK_MODE=clone` (already in `modules/shell/default.nix`) becomes
  effective: cache and projects share a filesystem, so uv reflinks venvs
  out of its cache instead of copying them (~59G of duplicates collapse).
- `modules/agents/pi.nix` still references `/mnt/LinuxData/Projects` —
  updated by the change's tasks once `~/Projects` is live.
- The NixOS side (`modules/hosts/legion/_hardware.nix`,
  `_disko.nix`, snapper timers) is prewired by the change for install day.

## Rollback

Revert the two fstab lines in Phase 2 and reboot: the root disk's `@home`
is untouched and booted as before.
