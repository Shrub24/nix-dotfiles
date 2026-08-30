# Design — Dual-Boot NixOS Install

## Context

`nixos-bare-metal-readiness` must first make `nixosConfigurations.shrub` a switchable, hardware-enabled NixOS host; this change then performs the install-day work it defers. The machine triple-boots Windows, Arch (Limine on a 512 GB Samsung), and — after this install — NixOS on a 2 TB SK hynix. The 2 TB disk holds Windows 500 GiB, Shared 150 GiB, and LinuxData 650 GiB around two retired Fedora partitions that, with existing gaps, form ~535.7 GiB of contiguous free space. The install must touch nothing owned by Windows or Arch, must identify every target by stable physical identity, and must stay reversible per step.

Two constraints shape everything below. First, **stable identity only**: disks are addressed by serial/WWN and partitions by PARTUUID/filesystem UUID, never `/dev/nvmeX`, which reorders across boots. Second, **hard gate**: no destructive task runs until `nixos-bare-metal-readiness` strict validation and a full toplevel build pass, because the switchable host must exist before install-day work can consume it.

## Goals / Non-Goals

**Goals:**

- Install NixOS permanently as a third, independently bootable OS: own 2 GiB ESP plus ~533.7 GiB LUKS2-encrypted Btrfs in the exact freed extent, with the agreed subvolume layout; only the dual-boot coexistence with Arch is a temporary soak.
- Keep Windows, Shared, LinuxData, and the Samsung disk's partition identities and bounds unchanged. Existing filesystem contents change only in dedicated cross-disk backup directories and through the reversible stale-UKI cleanup.
- Execute every destructive step with a precondition, backup, verification, and rollback checkpoint, re-checking serial/WWN/PARTUUID immediately before each command; back up both GPTs and every existing ESP first.
- Migrate durable state before activation: sops age keys, NetworkManager profiles, Tailscale/Bluetooth/SSH host key state, and the inventoried user data — with secrets never exposed. Set the login password after installation and before first boot.
- Verify boot through the new firmware entry, decryption, mounts, network, generation, desktop, secrets, and core services, and verify rollback to Arch as the escape hatch during the temporary soak.

**Non-Goals:**

- Arch retirement and reformatting its 310 GiB root into an encrypted Btrfs backup receiver (future change).
- TPM enrollment — LUKS2 passphrase only initially.
- Disk swap or hibernation — zram only.
- Growing LinuxData into the trailing ~27.3 GiB.
- Sharing the Arch ESP or changing application/service behavior — this change consumes existing capabilities and changes only install-time hardware metadata.

## Decisions

### D1. Hard gate on bare-metal readiness

The first install-day step is the gate, not a disk command: `nixos-bare-metal-readiness` strict validation must pass and a full `nixosConfigurations.shrub` toplevel build must succeed. Only then may the first destructive task run. No install-day step substitutes for the gate — it is the guarantee that the switchable host the install consumes actually exists.

### D2. Stable identity discipline

Every disk command resolves targets through `/dev/disk/by-id` (serial-based) and every partition through PARTUUID, re-checked immediately before the command executes:

```sh
# resolve once by serial, re-verify before each destructive command
disk=$(readlink -f /dev/disk/by-id/nvme-SK_hynix_SHGP31-2000GM_ADC5N475011305I3I)
fedora_esp=$(readlink -f /dev/disk/by-partuuid/9aae0356-4274-46c0-8593-bbcd9769b22f)
[ "$(lsblk -dno WWN "$disk")" = "nvme.1c5c-414443354e343735303131333035493349-5348475033312d32303030474d-00000001" ] || exit 1
[ "$(lsblk -no PKNAME "$fedora_esp")" = "$(basename "$disk")" ] || exit 1
```

The pattern — assert the expected serial/WWN/PARTUUID, abort otherwise — is applied before every destructive command, so a reordered NVMe or a mismatched layout stops the install before it can harm anything. No `/dev/nvmeX` reference ever reaches `_hardware.nix`.

### D3. Samsung disk: cleanup only

The 512 GB Samsung (MZVL2512HDJD-00BL2, serial `S6Z5NE0W500203`, WWN `eui.002538b531027bf1`) is read-only this change except one reversible cleanup. Arch Limine uses a separate current kernel/initramfs, so the 7.1.3 and 7.1.5 UKIs found by this audit are stale and unowned. At execution time the Samsung serial/WWN and the baseline-recorded Arch ESP PARTUUID are re-asserted, every UKI is backed up, and only UKIs that do not match the then-current kernel are moved off the ESP; `limine.conf` and the current kernel are re-checked immediately before cleanup. The matching UKI stays as an independent Arch rescue and the deduplicated Limine snapshot history is kept until Arch retirement.

### D4. Retired Fedora partition removal

On the 2 TB disk the retired Fedora 600 MiB ESP (PARTUUID `9aae0356-4274-46c0-8593-bbcd9769b22f`) and the retired Fedora 1 GiB ext4 (PARTUUID `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`) are removed — Fedora is confirmed retired. Before deletion both GPTs and the Windows, Arch, and Fedora ESPs are backed up cross-disk: the 2 TB GPT and Fedora ESP have a verified copy on the 512 GB Arch filesystem, while the 512 GB GPT and Windows/Arch ESPs have a verified copy on LinuxData. Serial/WWN/PARTUUID are then re-verified under the D2 pattern. After deletion the partition table is re-read to confirm the ~535.7 GiB contiguous freed extent and that the identities and bounds of Windows 500 GiB, Shared 150 GiB, and LinuxData 650 GiB are unchanged.

### D5. Provisioning the freed extent

The freed extent receives exactly two partitions: a 2 GiB FAT32 NixOS ESP (GPT type EF00, `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`) and a ~533.7 GiB Linux LUKS volume, aligned to the extent boundaries so no adjacent partition shifts. Formatting happens only with **new** filesystem UUIDs — none are invented in advance; the generated UUIDs and filesystem declarations are written into the curated `_hardware.nix` from the actual format output, replacing its existing Arch root/ESP declarations (which carry no LUKS initrd mapping). The ESP is formatted FAT32, mounted at `/mnt/boot` during the install, and is NixOS-owned; the Arch ESP is never shared.

### D6. Encryption, filesystem, and memory

LUKS2 with a passphrase only — no TPM enrollment in this install, so boot prompts for the passphrase and nothing depends on firmware attestation. The LUKS-header UUID is recorded via `cryptsetup luksUUID`, the container is opened as `cryptroot`, and Btrfs is formatted on `/dev/mapper/cryptroot`; later mount and configuration steps use that mapping, and `boot.initrd.luks.devices.cryptroot.device` gets the LUKS-header UUID — never the PARTUUID or Btrfs UUID. Inside LUKS, Btrfs with `zstd:3` and `noatime`. Swap is zram only; no swap partition/file and no hibernation, matching the identity the readiness change already established.

### D7. Subvolume and mount layout

One Btrfs with the standard layout: `@root`→`/`, `@home`→`/home`, `@nix`→`/nix`, `@log`→`/var/log`, `@snapshots`→`/.snapshots`, plus `@home-cache`→`/home/${primaryUser.name}/.cache` and `@containers`→`/home/${primaryUser.name}/.local/share/containers`. The two user-dependent targets are topology-derived — no hardcoded username literals, consistent with the composition invariants the readiness change inherits. `topology.hosts.arch` stays during dual boot — Arch remains an active host — and its rename is deferred to the Arch-retirement scope; `nixosConfigurations.shrub` and `networking.hostName = "shrub"` are unchanged.

### D8. Snapshot and data mounts

Snapper manages the root, home, and data Btrfs volumes. LinuxData keeps its current native-data mount — it is not resized, and its trailing ~27.3 GiB growth is explicitly out of scope. The Windows Shared NTFS mount keeps its existing `nofail` so a missing partition never blocks boot.

### D9. Firmware boot entries

The install registers a new NixOS firmware entry on the 2 TB disk; Windows and Arch entries remain untouched and selectable. The retired Fedora NVRAM entry is removed only after backup and provision verification — never speculatively, and never before NixOS boot is proven.

### D10. Install-day state migration

Before activation, the install provisions the root and primary-user sops age keys and NetworkManager profiles, and copies Tailscale state, Bluetooth pairing, and SSH host keys. Selected durable user state — browser profile, SSH, Syncthing, Grist, QMD/docs/projects, and anything else in the explicit inventory — is copied preserving ACLs, xattrs, and numeric IDs so ownership survives. Excluded: `~/.cache`, legacy standalone Home Manager/Nix profiles, and rootless container images (image activation reloads those after install). Secrets are copied in place and referenced by path; they never appear in any artifact. The login password is set after installation and before first boot via `nixos-enter --root /mnt -c 'passwd <topology-derived-user>'`, and never recorded.

### D11. Checkpoint discipline

Every destructive task carries the same four gates: precondition (identity + state assertions), backup (GPT, ESP, or prior state), verification of the result, and a rollback checkpoint. Rollback returns to the last checkpoint, so any failure strands the machine at a known-good state rather than mid-operation.

### D12. Install, verification, rollback

The full toplevel build never runs in installer tmpfs: after the generated metadata replaces the old Arch declarations in `_hardware.nix`, the change is committed and pushed, and strict validation plus a full `nixosConfigurations.shrub` build run from the Arch checkout. The NixOS media pass then mounts the new layout, clones and checks out the recorded pushed SHA at `/mnt/etc/nixos` in detached state — verifying `git rev-parse HEAD` equals it and `git status --porcelain` is empty before install; `nixos-generate-config` never runs over the curated repo — and installs with the pinned `nixos-install --root /mnt --flake /mnt/etc/nixos#shrub`, building into the target store. The login password is set via `nixos-enter --root /mnt -c 'passwd <topology-derived-user>'` and never recorded. Verification is sequential and explicit: firmware boot through the new entry, LUKS decryption, all mounts, network, NixOS and Home Manager generation, the desktop, secrets, and core services — then rollback to Arch is itself verified as the escape hatch during the temporary soak.

### D13. Future scope: Arch retirement

Arch retirement — converting its 310 GiB root into an encrypted Btrfs backup receiver — is a deliberate future change. The NixOS install itself is permanent; only the dual-boot coexistence is a temporary soak. This change leaves the Arch root byte-for-byte untouched so Arch remains a working rollback path throughout the soak, and `topology.hosts.arch` is renamed only in that retirement scope.

## Risks / Trade-offs

- [NVMe reordering or a mismatched layout points a destructive command at the wrong disk] → the D2 pattern asserts serial/WWN/PARTUUID immediately before every destructive command and aborts on mismatch; no `/dev/nvmeX` is ever encoded.
- [Data loss on Windows/Shared/LinuxData if the freed-extent calculation drifts] → GPT backed up, partition table re-read after Fedora removal, and new partitions created only within the verified ~535.7 GiB extent; adjacent partition sizes asserted unchanged.
- [State migration gaps leave the new host half-configured] → the durable-state inventory is explicit, migration preserves ACLs/xattrs/numeric IDs, and each class is verified before activation; excluded classes are named so nothing is silently dropped.
- [Secret exposure in artifacts] → keys are copied in place and referenced by path; no secret value is ever written to an artifact.
- [Boot failure strands the machine without a fallback] → the new NixOS entry is verified first, then rollback to Arch is verified as the escape hatch; the Fedora NVRAM entry is removed only after both.
- \[Generated UUIDs diverge from what `_hardware.nix` declares\] → UUIDs come from actual format output and replace the old Arch root/ESP declarations, never invented before formatting and never hand-edited to match an assumption.
- [A 34 GiB standalone toplevel build exhausts installer tmpfs] → the full build runs from the Arch checkout after the metadata commit is pushed; the media pass only runs `nixos-install --root /mnt --flake /mnt/etc/nixos#shrub`, building into the target store.
- [The installed system drifts from the validated configuration] → the exact validated/pushed SHA is checked out detached and verified clean at `/mnt/etc/nixos` and installed by the pinned command; `nixos-generate-config` never runs over the curated repo.
- [UKI cleanup removes a path Arch still needs] → every UKI is backed up, the UKI matching the then-current kernel and Limine history are kept, and `limine.conf`/current kernel are re-checked immediately before cleanup.
- [TPM-less passphrase is less convenient at every boot] → accepted trade for a simpler, firmware-independent trust model in this install; TPM enrollment can be added later without re-provisioning.

## Migration Plan

1. **Gate:** run `nixos-bare-metal-readiness` strict validation and a full `nixosConfigurations.shrub` toplevel build; nothing destructive starts before both pass.
1. **Baseline:** record serial/WWN/PARTUUID for both disks; back up both GPTs and all three existing ESPs (Windows, Arch, and Fedora).
1. **Samsung cleanup:** re-inventory and back up every UKI, then move only UKIs that do not match the then-current kernel off the Arch ESP; keep the matching rescue UKI and Limine history.
1. **Fedora removal:** back up the GPT and Fedora ESP, re-verify identities, remove the two retired partitions, confirm the ~535.7 GiB contiguous extent and untouched neighbors.
1. **Provision:** create the 2 GiB NixOS ESP (type EF00) and ~533.7 GiB LUKS2 in the extent; format the ESP FAT32 and LUKS2 (passphrase), record the LUKS-header UUID via `cryptsetup luksUUID`, open it as `cryptroot`, format Btrfs on `/dev/mapper/cryptroot`; create the full subvolume layout, mount it with `zstd:3`/`noatime` and the ESP at `/mnt/boot`, and capture the new filesystem UUIDs.
1. **Merge:** replace the old Arch root/ESP declarations in the curated `_hardware.nix` with the generated UUID and filesystem declarations — new ESP UUID at `/boot`, actual LUKS-header UUID in `boot.initrd.luks.devices.cryptroot`, Btrfs UUID with all seven mounts, Shared/LinuxData preserved; no `/dev/nvmeX`.
1. **Validate:** commit and push the metadata change, then from the Arch checkout re-run strict validation and the full toplevel build — never in installer tmpfs.
1. **Stage:** boot NixOS media, mount the new layout, provision root/user age keys and NetworkManager profiles, and copy Tailscale/Bluetooth/SSH host keys plus selected user state with ACLs/xattrs/numeric IDs (excluding `~/.cache`, standalone profiles, and rootless container images); clone and check out the recorded pushed SHA detached at `/mnt/etc/nixos`, verified clean.
1. **Install:** run `nixos-install --root /mnt --flake /mnt/etc/nixos#shrub` (builds into the target store), set the login password via `nixos-enter --root /mnt -c 'passwd <topology-derived-user>'` before reboot, and verify firmware boot, decryption, mounts, network, NixOS and Home Manager generation, desktop, secrets, and core services; verify rollback to Arch; remove the Fedora NVRAM entry only after verification.
1. **Defer:** leave Arch retirement and its 310 GiB root conversion to a future change.
