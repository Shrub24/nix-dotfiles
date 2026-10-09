# Design — Dual-Boot NixOS Install

## Context

`nixos-bare-metal-readiness` must first make `nixosConfigurations.legion` a switchable, hardware-enabled NixOS host; this change then performs the install-day work it defers. The machine currently triple-boots Windows and Arch (Limine, on a 512 GB Samsung NVMe). NixOS replaces Windows at the head of that Samsung disk, and the retired Fedora partitions on the 2 TB SK hynix are removed so the space is free for an eventual Windows reinstall. Arch stays bootable through a soak, then its partitions and the surviving Windows remnant are deleted and the NixOS root grows to the rest of the disk.

Two constraints shape everything below. First, **stable identity only**: disks are addressed by serial/WWN and partitions by PARTUUID or partlabel, never `/dev/nvmeX`, which reorders across boots. Second, **hard gate**: no destructive task runs until `nixos-bare-metal-readiness` strict validation and a full toplevel build pass, because the switchable host must exist before install-day work can consume it.

Measured on 2026-09-29 (512 B sectors). Samsung `MZVL2512HDJD-00BL2`, serial `S6Z5NE0W500203`, WWN `eui.002538b531027bf1`, 1,000,215,216 sectors (476.94 GiB): p1 vfat Windows ESP 100 MiB `2193a654-…` at 2048–206847, p2 MSR 16 MiB `031ea351-…`, p3 NTFS Windows C: `9ce9fe67-…` to sector 343046143, p5 btrfs Arch root 310.5 GiB `e33cb524-…`, p6 vfat Arch/Limine ESP 2 GiB `1a2c5601-…`, p4 NTFS WinRE `b5c0d8da-…` at the tail. SK hynix `SHGP31-2000GM`, serial `ADC5N475011305I3I`: p1 MSR, p2 NTFS 500 GiB and p3 NTFS `Shared` 150 GiB (both kept), p4 retired Fedora ESP 600 MiB `9aae0356-…`, p5 retired Fedora ext4 1 GiB `16921d6b-…`, p7 btrfs LinuxData 650 GiB `47fa5ee2-…` with `@home` and `@data` (kept).

## Goals / Non-Goals

**Goals:**

- Install NixOS permanently as the head of the Samsung disk: a 2 GiB ESP plus a LUKS2-encrypted btrfs root, with the agreed subvolume layout; only the coexistence with Arch is a temporary soak.
- Keep the data disk untouched: `/home` and `/data` stay on LinuxData exactly as `_storage.nix` states, through the install and after it.
- Carry the root state that identifies the machine, so the tailnet node, the fleet's pinned SSH host key and the sops key survive the new root.
- Derive every root-disk mount from one declaration, so no install-day UUID is hand-edited into the configuration and the validated configuration is the installed one.
- Execute every destructive step with a precondition, backup, verification, and rollback checkpoint, re-checking serial/WWN/PARTUUID immediately before each command.
- Close the loop after a soak: delete Arch and the Windows remnant, grow the root to the whole disk.

**Non-Goals:**

- TPM enrolment — LUKS2 passphrase only initially.
- Disk swap or hibernation — zram only.
- Growing LinuxData into its trailing ~27.3 GiB.
- Reinstalling Windows — the freed SK hynix extent is left for it, and that install is a separate operator job.
- Changing application or service behavior: this change consumes existing capabilities and changes only the host's disk layout and hardware metadata.

## Decisions

### D1. Hard gate on bare-metal readiness

The first install-day step is the gate, not a disk command: `nixos-bare-metal-readiness` strict validation must pass and a full `nixosConfigurations.legion` toplevel build must succeed, from the Arch checkout. No install-day step substitutes for the gate. Because the disk layout now derives from the disko declaration (D8), the build that passes this gate is the configuration that gets installed — there is no metadata step between them, and the gate therefore gates the exact artifact.

### D2. The install target is the head of the Samsung disk

NixOS takes the extents Windows occupies: p1, p2 and p3 (sectors 2048–343046143) are deleted and replaced by a 2 GiB ESP (sectors 2048–4196351, GPT type EF00) and a LUKS partition (sectors 4196352–343046143, 161.58 GiB during the soak). The LUKS partition is last, so growing it post-soak is one `sgdisk --move-end` plus `cryptsetup resize` plus `btrfs filesystem resize max`. The alternative — the retired Fedora extent on the SK hynix, which the original draft used — was rejected because it splits the machine's OSes across two disks and spends the only contiguous free extent Windows could be reinstalled into.

### D3. Stable identity discipline

Every disk command resolves targets through `/dev/disk/by-id` (serial-based) and every partition through PARTUUID or partlabel, re-checked immediately before the command executes:

```sh
# resolve once by serial, re-verify before each destructive command
disk=$(readlink -f /dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00BL2_S6Z5NE0W500203)
windows_c=$(readlink -f /dev/disk/by-partuuid/9ce9fe67-debb-43d8-9dc5-2017ef5b2175)
[ "$(lsblk -no PKNAME "$windows_c")" = "$(basename "$disk")" ] || exit 1
```

Firmware entries get the same treatment: they are resolved by the label recorded in the baseline (`Windows Boot Manager`, `Fedora`, `Limine`) and their `BootNNNN` ids re-read from `efibootmgr` immediately before deletion, because the ids are assigned by the firmware rather than owned by this repository.

### D4. Windows' backup is confirmed before the first delete

Deleting p1–p3 is not reversible on this machine. The GPT backup restores the partition entries and the Windows ESP image restores the boot files, but once the LUKS header and the btrfs are written, the extents held by Windows C: are gone; only the operator's own Windows backup can bring them back. The first destructive task therefore stops and requires explicit confirmation of where that backup is and that it has been verified, before any delete command runs. The same reasoning names the Windows ESP in the cross-disk backup set: with it, a restored GPT plus a future Windows install still boots.

### D5. The install runs from the running Arch system

**Verdict: adopt.** `nixos-install` from nixpkgs, run on the running pre-install system into a mounted target root, is the primary path; NixOS media is the documented fallback. nix is already installed, `nixos-install-tools` evaluates and builds there (`nixpkgs#nixos-install-tools` builds from cache), and the install is a chroot install either way — `nixos-install` runs the target's `switch-to-configuration boot` inside `nixos-enter`.

Reasons it holds:

- **No installer tmpfs.** nixos-install builds into the target store with the running system's store as an extra substituter (`sub="auto?trusted=1"` with `--store "$mountPoint"`), so a toplevel already present in the local store is _copied_, not rebuilt. The original draft's worst constraint — a ~34 GiB toplevel build inside the installer's overlay — disappears. The constraint that replaces it is free space on the Arch root (55 GiB available, 82% used), checked before the build.
- **The gate can run before anything is destroyed.** The build, and therefore the validation of the exact configuration that gets installed, happens on the machine as it is now, with no media round trip.
- **Root state copies directly.** `/etc/ssh/ssh_host_*`, `/var/lib/sops-nix/key.txt`, `/var/lib/tailscale`, `/var/lib/bluetooth` and the NetworkManager profiles live on the running root; copying them into the mount is a local `cp`, introducing no SSH or rsync path and no secret over the wire.
- **Nothing being rewritten is in use.** p1–p3 hold Windows, p2 is an MSR, and none is mounted; Arch's root and ESP (p5, p6) are untouched, so the disk being repartitioned is not the disk being booted from in any part that changes.

Risks it carries, and how the plan answers them:

- **Repartitioning the disk that holds the running root.** The GPT edit itself is a write to the table area; the kernel is made to re-read it with `partx -u` (per-partition BLKPG deltas), not `partprobe`/`BLKRRPART`, which fails with `EBUSY` when any partition of that disk is open — and p5 is the running root. If the re-read still refuses, the new nodes appear after a reboot into Arch; the plan resumes there, because no later step depends on the re-read having happened in the same boot.
- **The EFI variable write from the chroot.** `nixos-enter` does `mount --rbind /sys "$mountPoint/sys"`, which carries the `efivarfs` mount into the chroot, so `boot.loader.efi.canTouchEfiVariables = true` and systemd-boot's `bootctl install` write the new `BootNNNN` entry. The plan asserts `/sys/firmware/efi/efivars` exists and is writable before starting, so a legacy-mode boot is caught before the install rather than after it.
- **A tree the operator has edited.** The gate build runs in an export of the recorded SHA, never the operator's working tree, so uncommitted changes cannot reach the installed system — and the install then takes the object that passed the gate rather than re-evaluating the flake as root.
- **Arch changes under the install.** The skeptical case for media is a running system that cannot be trusted; that risk is real but smaller than the tmpfs-build and state-copy costs, and the fallback is one ISO boot away.

The fallback differs only in where the closure comes from: media must build it inside the installer's store, so the same recorded SHA is cloned to `/mnt/etc/nixos` and installed with `nixos-install --root /mnt --flake /mnt/etc/nixos#legion`.

### D6. Encryption, filesystem, and memory

LUKS2 with a passphrase only — no TPM enrolment, so boot prompts and nothing depends on firmware attestation. Discards pass through (`allowDiscards`) so the btrfs `discard=async` mount option reaches the SSD, matching the laptop's LUKS settings. Inside the container, btrfs with `zstd:3` and `noatime`, `ssd`, `discard=async`, `space_cache=v2`. Swap is zram only, as the readiness change established: no swap partition, no hibernation, no resume device.

### D7. Subvolume and mount layout

One btrfs on the LUKS container carries the system tree: `@`→`/`, `@nix`→`/nix`, `@cache`→`/var/cache`, `@log`→`/var/log`, `@tmp`→`/var/tmp`, `@images`→`/var/lib/libvirt/images`, `@snapshots`→`/.snapshots`. The filesystem is fresh, so this is the moment to settle the naming the draft left inconsistent: `@` is what the live Arch root, `_hardware.nix` and the laptop's disk all use, and `@root` was the outlier — the set above uses `@` everywhere, in the declaration, the install steps and the prose.

`/home` is deliberately **not** on this volume. It belongs to LinuxData, declared once as `storage.dataDisk` in `modules/hosts/legion/_storage.nix`; the install neither creates nor moves it, so home's churn subvolumes are not this change's to touch. No user-dependent path is named here, so no username literal appears. Identity is unchanged: `nixosConfigurations.legion`, `networking.hostName = "legion"` and `topology.hosts.legion` are correct as declared and stay so; the draft's "rename is deferred" note referred to a hostname that no longer exists anywhere in the tree.

### D8. Root-disk mounts come from the disko declaration; the data disk does not

`_hardware.nix` declares no root-disk mount. `_disko.nix` is imported through `inputs.disko.nixosModules.disko`, exactly as `modules/hosts/spectre.nix` does, so `fileSystems` for `/`, `/nix`, `/var/cache`, `/var/log`, `/var/tmp`, `/var/lib/libvirt/images`, `/.snapshots` and `/boot`, plus `boot.initrd.luks.devices.cryptroot`, are rendered from one declaration. The devices are a partlabel (`/dev/disk/by-partlabel/disk-samsung-ESP`, `disk-samsung-cryptroot`) and a mapper name (`/dev/mapper/cryptroot`), so the install writes no UUID into the configuration and the gate builds the exact layout it installs.

The data disk is _not_ in the declaration, deliberately diverging from the earlier draft that captured both disks. Its mounts stay derived from `_storage.nix` by UUID in `_hardware.nix`: that UUID is already known rather than install-day, the disk is never partitioned by this change, and a disko-rendered device would be a partlabel (`disk-<name>-data`) the live partition does not carry — an installed system that cannot mount `/home`. `_storage.nix` keeps its `@home`/`@data` names, its UUID and its mount options as the single source for those two mounts. With that, the draft's promised eval assertion ("disko renders exactly the declaration's subvolume set") has nothing to assert over and is dropped rather than reimplemented; the equality it was protecting is now structural, because the mounts have one owner each.

### D9. Retired Fedora removal, and what the freed space is for

On the SK hynix, the retired Fedora ESP (600 MiB, `9aae0356-…`) and the retired Fedora ext4 (1 GiB, `16921d6b-…`) are removed after the GPT backup, with Windows 500 GiB, Shared 150 GiB and LinuxData 650 GiB asserted unchanged. Nothing is created in their place: the freed extent plus the existing gaps around them is left unpartitioned, because it is where the eventual Windows reinstall goes. Nothing this change does writes into it, so the Fedora ext4's contents remain physically intact and a restored GPT would make them visible again until that reinstall happens.

### D10. Firmware boot entries

The install registers a new NixOS entry on the new ESP. The entries pointing at what this change deletes are removed at install time: `Windows Boot Manager` (its ESP is gone) and `Fedora`. `Limine` stays for the soak, because Arch must stay bootable as the rollback path, and is removed in the post-soak step, after Arch's ESP is deleted.

### D11. Root state is carried; user state is not migrated

"Install-day state provisioning" in the draft migrated browser profiles, service data and project trees. None of that is needed now: `/home` never moves, so all of it is already in place on LinuxData. What must be carried is the root state that makes the machine _itself_, because losing it breaks the fleet rather than one login:

- `/etc/ssh/ssh_host_*` — nix-fleet pins legion's ed25519 host key, and sops renders through `sshKeyPaths`;
- `/var/lib/sops-nix/key.txt` — the age key the system's secrets decrypt with;
- `/var/lib/tailscale` — the tailnet node identity;
- `/var/lib/bluetooth` — pairing keys;
- a subset of `/etc/NetworkManager/system-connections/*.nmconnection`, kept as an explicit list the operator fills in before the copy runs. The requirement is that the list is explicit, not that it is exhaustive: a profile that carries a network the machine cannot rejoin without user input belongs on it, and the other twenty-odd do not.

Not carried: ollama, docker and flatpak state. Those services re-create and re-fetch what they hold, and carrying them would add tens of gigabytes to the install for no identity gain. The login password is set after installation and before the first boot, and is never recorded.

### D12. Checkpoint discipline, and what each rollback actually restores

Every destructive task carries four gates: precondition (identity and state assertions), backup, verification of the result, and a rollback checkpoint. Rollback returns to the last checkpoint, and the plan states per step what that checkpoint is worth:

- Fedora removal: reversible from the GPT backup alone, because nothing writes into the freed extent.
- Windows removal: reversible only as a partition table and an ESP image; the C: contents are the operator's backup (D4).
- Root provisioning: reversible by re-creating the ESP and LUKS partition — nothing before the install's store copy is worth keeping.
- The install: reversible by booting Arch, which is untouched until the soak ends.
- The post-soak grow: **not** reversible. It overwrites Arch's partitions and the Windows remnant with the grown root, so it runs only when the soak has been ended deliberately, and the Arch root is never backed up (310 GiB of retired OS).

### D13. Soak, then consolidation

The soak is a period of ordinary use with three things true: NixOS boots and is the daily system, Arch still boots through Limine, and the freed SK hynix extent stays free. It ends when the operator says so — verified rollback to Arch is the escape hatch throughout, not an exit from the plan. Consolidation then deletes p5 (Arch root), p6 (Arch ESP) and p4 (WinRE), grows the LUKS partition from 4196352 to the GPT last usable sector, and runs `cryptsetup resize cryptroot` with `btrfs filesystem resize max /`. The final layout is a 2 GiB ESP and a root that owns the rest of the disk, with a single NixOS firmware entry.

## Risks / Trade-offs

- [NVMe reordering or a mismatched layout points a destructive command at the wrong disk] → D3 asserts serial/WWN/PARTUUID/partlabel immediately before every destructive command and aborts on mismatch; `_disko.nix` addresses the disk by-id.
- [Windows C: is lost with no backup] → D4's stop, before the first delete: the plan requires explicit confirmation that the Windows backup exists and is verified.
- [A kernel re-read failure during the repartition looks like a failure of the whole plan] → `partx -u` per-partition deltas, never `partprobe`; the documented fallback is a reboot into Arch and resume, since no later step depends on the re-read happening in that boot.
- [The EFI variable write fails inside the chroot] → `nixos-enter` bind-mounts `/sys` recursively, carrying `efivarfs`; the plan asserts `/sys/firmware/efi/efivars` is present and writable before starting.
- [The toplevel cannot be built or copied for lack of space] → the free-space check runs before the build (55 GiB free on a 82%-full Arch root), and the target's 161.58 GiB soak extent holds the ~34 GiB closure with room for the install.
- [The installed system drifts from the validated configuration] → the export is a clean checkout of the recorded SHA, verified with `git rev-parse HEAD` and `git status --porcelain`; `nixos-generate-config` never runs over the curated repo; the flake is not edited between the gate and the install.
- [State migration gaps leave the new host half-configured] → the carried set is enumerated in D11 and verified item by item, including the operator's NetworkManager keep-list, before the first boot.
- [Secret exposure in artifacts] → keys are copied in place and referenced by path; no secret value is written to an artifact or the Execution Record.
- [Boot failure strands the machine without a fallback] → NixOS boot is verified before the Fedora and Windows entries are removed, and Arch is verified bootable afterwards; the post-soak grow runs only after the soak.
- [TPM-less passphrase is less convenient at every boot] → accepted trade for a firmware-independent trust model; TPM enrolment can be added later without re-provisioning.

## Migration Plan

1. **Gate:** Windows backup confirmed; strict validation and a full `nixosConfigurations.legion` toplevel build from the Arch checkout; free space and efivars asserted.
1. **Baseline and backups:** serial/WWN/PARTUUID/partlabel for both disks, both GPTs, all three ESPs (Windows, Arch, Fedora) and the current kernel and `limine.conf`, backed up cross-disk with checksums.
1. **Samsung:** delete p1–p3, create the 2 GiB EF00 ESP (partlabel `disk-samsung-ESP`) and the LUKS partition to sector 343046143 (partlabel `disk-samsung-cryptroot`), re-read with `partx -u`, assert p5/p6 unchanged.
1. **Provision:** format the ESP, `luksFormat` LUKS2 with a passphrase, open as `cryptroot`, `mkfs.btrfs`, create the seven subvolumes, mount the layout at `/mnt` with the declared options plus the data disk's `@home` and `@data` at `/mnt/home` and `/mnt/data` and the ESP at `/mnt/boot`.
1. **SK hynix:** delete the two retired Fedora partitions, assert the kept partitions unchanged, then copy that disk's GPT and ESP backup into the new root so it outlives Arch.
1. **State:** copy the D11 root state into `/mnt`, including the operator's NetworkManager keep-list, and verify each item.
1. **Install:** `nixos-install --root /mnt --system <toplevel built from the clean export of the recorded SHA> --no-root-passwd`, set the login password with `nixos-enter`, remove the Windows and Fedora firmware entries.
1. **Verify:** boot NixOS through the new entry (LUKS prompt, mounts, network, Home Manager generation, desktop, secrets, services), then boot Arch and confirm the rollback path.
1. **Soak:** NixOS daily, Arch still bootable, freed extent untouched.
1. **Consolidate:** delete p5, p6 and p4, grow the LUKS partition to the disk end, `cryptsetup resize`, `btrfs filesystem resize max`, remove the Limine entry, verify the final layout.
1. **Defer:** the Windows reinstall into the SK hynix's freed extent, and LinuxData's trailing ~27.3 GiB.
