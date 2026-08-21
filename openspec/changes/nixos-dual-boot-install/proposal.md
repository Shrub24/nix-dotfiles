## Why

`nixos-bare-metal-readiness` must first make `nixosConfigurations.shrub` a
switchable, hardware-enabled NixOS host. This change then performs the
install-day work it defers: partition editing on the 2 TB disk, new ESP/LUKS/Btrfs
provisioning, install-day state migration, `nixos-install`, boot verification,
and rollback. It does **not** retire Arch — Windows and Arch stay bootable, and
Arch's 310 GiB partition is deliberately left untouched for a future change.

## What Changes

### Disk identity discipline

- Disks are identified by stable physical serial/WWN, partitions by
  PARTUUID/UUID — never `/dev/nvme0n1` numbering. Every destructive task
  re-checks these identifiers, requires explicit user approval, and verifies
  its result before proceeding.
- Back up both GPTs and all three existing ESPs (Windows, Arch, and retired
  Fedora) before any destructive operation. Rollback checkpoints are taken per
  destructive task. No disk command is executed by drafting this change.

### 512 GB Samsung (MZVL2512HDJD-00BL2, serial `S6Z5NE0W500203`) — cleanup only

- Windows boot, 163.5 GiB NTFS, and 310.5 GiB Arch Btrfs keep their partition
  identities and contents. The 2 GiB Arch/Limine ESP remains bootable, with
  only the reversible stale-UKI cleanup.
- Arch Limine uses separate kernel/initramfs; the 7.1.3 and 7.1.5 UKIs found by
  this audit are stale/unowned. Re-inventory before cleanup, back up every UKI,
  move only UKIs that do not match the then-current kernel, and keep the
  matching UKI as an independent Arch rescue. Keep the legitimate deduplicated
  Limine snapshot history until Arch retirement.

### 2 TB SK hynix (SHGP31-2000GM, serial `ADC5N475011305I3I`) — provisioning

- Windows 500 GiB, Shared 150 GiB, and LinuxData 650 GiB keep their partition
  identities and bounds; only a dedicated cross-disk backup directory is added
  to LinuxData.
- Remove the retired Fedora 600 MiB ESP (PARTUUID
  `9aae0356-4274-46c0-8593-bbcd9769b22f`) and the retired Fedora 1 GiB ext4
  (PARTUUID `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`). Together with existing
  gaps these form ~535.7 GiB contiguous free space.
- Provision in that gap: a 2 GiB NixOS ESP plus ~533.7 GiB LUKS2
  passphrase-encrypted Btrfs. No TPM unlock initially; zram only, no disk swap
  or hibernation.
- LinuxData keeps its current native-data mount. Growing it into the trailing
  ~27.3 GiB is optional and not part of this install.
- NixOS has its own ESP on the 2 TB disk — the Arch ESP is not shared. NixOS,
  Windows, and Arch each remain independently bootable through firmware
  entries.

### Subvolumes and mount options

- `@root` → `/`, `@home` → `/home`, `@nix` → `/nix`, `@log` → `/var/log`,
  `@snapshots` → `/.snapshots`, `@home-cache` → the primary user's cache,
  `@containers` → the primary user's rootless container storage.
- Compression `zstd:3`, `noatime`. Periodic fstrim is already config-owned.
- The final configuration uses topology identity for the user — no hardcoded
  username literals.

### Install-day state provisioning

- Before activation, provision the root and user sops age keys and
  NetworkManager profiles, and preserve Tailscale state, Bluetooth pairing,
  and SSH host keys. Set the login password after installation and before the
  first boot.
- Migrate selected user state/data, preserving service data such as Grist, the
  browser profile, SSH, Syncthing, and QMD/docs/project data.
- Exclude `~/.cache`, legacy standalone Home Manager/Nix profiles, and rootless
  container images (rebuilt/reloaded after install). Secrets are never exposed
  in artifacts.

### Install, boot verification, rollback

- Run `nixos-install` against the new ESP and LUKS root, then verify boot
  through the new firmware entry while Windows and Arch remain selectable.
- Every destructive step is backed up and verifiable; rollback returns to the
  last checkpoint. Arch retirement — and converting its 310 GiB partition to an
  encrypted Btrfs backup receiver — is a future change, explicitly out of
  scope here.

## Capabilities

### New Capabilities

- `nixos-dual-boot-install`: The dual-boot NixOS install procedure — stable
  identifier discipline, GPT/ESP backup, retired-partition removal, ESP/LUKS2
  Btrfs provisioning, subvolume layout, install-day state migration,
  `nixos-install`, boot verification, and rollback checkpoints — without
  touching Windows or Arch.

### Modified Capabilities

- None. This change is operational: it consumes existing capabilities
  (`nixos-bare-metal-readiness` as a hard dependency, plus
  `system-manager-foundation`, `dendritic-module-composition`, and
  `secrets-ownership-model`) rather than altering their specs.

## Impact

- 2 TB disk: two retired Fedora partitions removed; a 2 GiB NixOS ESP and
  ~533.7 GiB LUKS2 Btrfs created with the subvolume layout above.
- 512 GB disk: only backed-up UKIs that fail the install-day current-kernel
  check leave the Arch ESP; all Windows, Arch, and Limine content otherwise
  remains unchanged.
- No flake or module behavior changes in this change — the switchable host must
  already exist via `nixos-bare-metal-readiness`. `_hardware.nix` receives the
  generated install-time UUIDs and mount declarations.
- Boot: a new NixOS firmware entry on the 2 TB disk; Windows and Arch remain
  independently bootable. Post-soak Arch retirement is a separate future
  change.
