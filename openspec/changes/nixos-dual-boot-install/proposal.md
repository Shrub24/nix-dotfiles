# Proposal — Dual-Boot NixOS Install

## Why

`nixos-bare-metal-readiness` must first make `nixosConfigurations.legion` a switchable, hardware-enabled NixOS host. This change then performs the install-day work it defers: removing Windows from the head of the 512 GB Samsung, provisioning the ESP and LUKS root there, carrying the root state that identifies the machine, installing from the running Arch system, verifying boot, and — after a soak — deleting Arch and growing the root to the whole disk.

The placement changed from the original draft. It put NixOS in the retired-Fedora extent on the 2 TB SK hynix; that split the machine's OSes across two disks and spent the only contiguous free extent Windows could be reinstalled into. NixOS takes the Windows extents on the Samsung instead, Windows is not reinstalled in this change, and the SK hynix's freed extent is left for that reinstall later.

## What Changes

### Disk identity discipline

- Disks are identified by stable physical serial/WWN, partitions by PARTUUID or partlabel — never `/dev/nvme0n1` numbering. Every destructive task re-checks these identifiers, requires explicit user approval, and verifies its result before proceeding.
- Both GPTs and all three existing ESPs (Windows, Arch, Fedora) are backed up cross-disk before any destructive operation. Rollback checkpoints are taken per destructive task, and the plan records what each one can actually restore. No disk command is executed by drafting this change.
- **The plan stops before the first delete to confirm the Windows C: backup exists and is verified.** The Windows extents become the LUKS root; no backup taken from this machine can bring that data back.

### 512 GB Samsung (MZVL2512HDJD-00BL2, serial `S6Z5NE0W500203`) — install target

- Windows boot, the MSR, and the 163.5 GiB NTFS volume (sectors 2048–343046143) are deleted and replaced by a 2 GiB FAT32 ESP at the head of the disk and a LUKS2-encrypted btrfs root filling the rest of that extent (161.58 GiB during the soak).
- Arch's root and Arch/Limine ESP (p5, p6) keep their identities, bounds and contents, and Arch stays bootable through the soak as the rollback path.
- Provisioning: FAT32 ESP with partlabel `disk-samsung-ESP`; LUKS2 with a passphrase only (no TPM), opened as `cryptroot`, partlabel `disk-samsung-cryptroot`; btrfs on `/dev/mapper/cryptroot`; `zstd:3` and `noatime`. Swap is zram only — no swap partition and no hibernation.
- The disk is addressed by-id in the configuration and by serial/WWN at the command line, and the kernel's partition-table re-read uses `partx -u` — `partprobe`/`BLKRRPART` fails while the running root is open.

### 2 TB SK hynix (SHGP31-2000GM, serial `ADC5N475011305I3I`) — cleanup only

- Windows 500 GiB, Shared 150 GiB and LinuxData 650 GiB keep their partition identities, bounds and contents. `/home` and `/data` stay on LinuxData throughout, exactly as `_storage.nix` declares them — the install neither moves nor reforms them.
- The retired Fedora 600 MiB ESP (PARTUUID `9aae0356-4274-46c0-8593-bbcd9769b22f`) and retired Fedora 1 GiB ext4 (PARTUUID `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`) are removed and nothing is created in their place: the freed extent is where the eventual Windows reinstall goes.
- The SK hynix GPT and Fedora ESP backup is copied into the new root before Arch is deleted, so the only copy of that disk's table does not leave with Arch.

### Subvolumes and mounts

- `@` → `/`, `@nix` → `/nix`, `@cache` → `/var/cache`, `@log` → `/var/log`, `@tmp` → `/var/tmp`, `@images` → `/var/lib/libvirt/images`, `@snapshots` → `/.snapshots` — all on the LUKS container. The naming follows the live Arch root and the laptop's disk; the draft's `@root` spelling is dropped.
- `/home` and `/data` stay on LinuxData; no home subvolume is created on the LUKS and no user-dependent path is named, so no username literal appears.
- Root-disk mounts derive from the disko declaration in `_disko.nix`, imported through disko's NixOS module as `modules/hosts/spectre.nix` imports it for the laptop, so `fileSystems` and `boot.initrd.luks.devices` have one owner and no install-day UUID is hand-edited into `_hardware.nix`. The data disk stays out of that declaration: its mounts already derive from `_storage.nix` by UUID, and disko would render a partlabel the live partition does not carry.
- `topology.hosts.legion`, `nixosConfigurations.legion` and `networking.hostName = "legion"` are unchanged and correct as declared.

### Root state carried, user state left alone

- `/home` never moves, so no user data migration is needed. What is carried into the new root is what makes the machine itself: `/etc/ssh/ssh_host_*` (nix-fleet pins legion's ed25519 key and sops renders through `sshKeyPaths`), `/var/lib/sops-nix/key.txt`, `/var/lib/tailscale`, `/var/lib/bluetooth`, and an explicit operator-filled keep-list of `/etc/NetworkManager/system-connections/*.nmconnection` profiles.
- Not carried: ollama, docker and flatpak state — those re-create what they hold, and carrying them buys no identity.
- The login password is set after installation and before the first boot with `nixos-enter --root /mnt -c 'passwd <topology-derived-user>'`, and is never recorded.

### Install from the running Arch system

- **Adopted.** `nixos-install` from nixpkgs, run on the running Arch host into the mounted target, is the primary path: nix is already installed, the toplevel copies from the local store instead of being rebuilt inside installer tmpfs, the gate build validates the exact configuration that gets installed, and the root state copies directly. Repartitioning the disk that holds the running root is safe because only non-busy partitions change, and the chroot's EFI variable write works because `nixos-enter` carries `efivarfs` in on a recursive `/sys` bind.
- NixOS media is the documented fallback; the only difference is that the closure is built inside the installer's store.
- In both paths the install source is a clean checkout of the recorded gate SHA — `git rev-parse HEAD` verified equal and `git status --porcelain` empty — and `nixos-generate-config` never runs over the curated repo.

### Firmware entries, soak, consolidation

- The install registers a new NixOS entry on the new ESP and removes the two entries that point at deleted partitions — `Windows Boot Manager` and `Fedora` — matched by the baseline's label and re-read `BootNNNN` id immediately before deletion. `Limine` stays, because Arch must stay bootable through the soak.
- The soak ends deliberately: p5, p6 and p4 are deleted, the LUKS partition grows to the last sector of the disk (474.94 GiB), `cryptsetup resize cryptroot` and `btrfs filesystem resize max /` follow, and the Limine entry is removed. That group is not reversible, and the plan says so.

## Capabilities

### New Capabilities

- `nixos-dual-boot-install`: The dual-boot NixOS install procedure — stable identifier discipline, GPT/ESP backup, Windows and retired-Fedora removal, ESP/LUKS2 btrfs provisioning, subvolume layout, root-state carry, install from the running system, boot verification, the soak, and post-soak consolidation — without touching the data disk.

### Modified Capabilities

- None. This change is operational: it consumes existing capabilities (`nixos-bare-metal-readiness` as a hard dependency, plus `storage-topology`, `system-manager-foundation`, `dendritic-module-composition`, and `secrets-ownership-model`) rather than altering their specs. The root-disk fileSystems move from `_hardware.nix` to the disko declaration, which changes where a fact lives, not which facts are mounted.

## Impact

- 512 GB disk: Windows p1–p3 deleted and replaced by a 2 GiB NixOS ESP and a 161.58 GiB LUKS2 btrfs root, growing to 474.94 GiB after the soak; Arch p5/p6 untouched until consolidation, then deleted.
- 2 TB disk: two retired Fedora partitions removed and the freed extent left free; Windows, Shared and LinuxData keep their identities and bounds.
- No application or service behavior changes. `modules/hosts/legion/_disko.nix` becomes the root-disk declaration, `modules/hosts/legion/_hardware.nix` keeps the data disk and Shared mounts plus hardware policy, and `modules/hosts/legion.nix` gains the two-line disko import.
- Boot: a new NixOS firmware entry; Windows and Fedora entries removed at install time, Limine kept until consolidation.
