# Design — Dual-Boot NixOS Install

## Context

`nixos-bare-metal-readiness` must first make `nixosConfigurations.shrub` a switchable, hardware-enabled NixOS host; this change then performs the install-day work it defers. The machine triple-boots Windows, Arch (Limine on a 512 GB Samsung), and — after this install — NixOS on a 2 TB SK hynix. The 2 TB disk holds Windows 500 GiB, Shared 150 GiB, and LinuxData 650 GiB around two retired Fedora partitions that, with existing gaps, form ~535.7 GiB of contiguous free space. The install must touch nothing owned by Windows or Arch, must identify every target by stable physical identity, and must stay reversible per step.

Two constraints shape everything below. First, **stable identity only**: disks are addressed by serial/WWN and partitions by PARTUUID/filesystem UUID, never `/dev/nvmeX`, which reorders across boots. Second, **hard gate**: no destructive task runs until `nixos-bare-metal-readiness` strict validation and a full toplevel build pass, because the switchable host must exist before install-day work can consume it.

## Goals / Non-Goals

**Goals:**

- Install NixOS as a third, independently bootable OS: own 2 GiB ESP plus ~533.7 GiB LUKS2-encrypted Btrfs in the exact freed extent, with the agreed subvolume layout.
- Keep Windows, Shared, LinuxData, and the Samsung disk's partition identities and bounds unchanged. Existing filesystem contents change only in dedicated cross-disk backup directories and through the reversible stale-UKI cleanup.
- Execute every destructive step with a precondition, backup, verification, and rollback checkpoint, re-checking serial/WWN/PARTUUID immediately before each command; back up both GPTs and every existing ESP first.
- Migrate durable state before activation: sops age keys, NetworkManager profiles, Tailscale/Bluetooth/SSH host key state, and the inventoried user data — with secrets never exposed. Set the login password after installation and before first boot.
- Verify boot through the new firmware entry, decryption, mounts, network, generation, desktop, secrets, and core services, and verify rollback to Arch.

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

The 512 GB Samsung (MZVL2512HDJD-00BL2, serial `S6Z5NE0W500203`, WWN `eui.002538b531027bf1`) is read-only this change except one reversible cleanup. Arch Limine uses a separate current kernel/initramfs, so the 7.1.3 and 7.1.5 UKIs found by this audit are stale and unowned. At execution time every UKI is backed up, and only UKIs that do not match the then-current kernel are moved off the ESP. The matching UKI stays as an independent Arch rescue and the deduplicated Limine snapshot history is kept until Arch retirement. `limine.conf` and the current kernel are re-checked immediately before cleanup.

### D4. Retired Fedora partition removal

On the 2 TB disk the retired Fedora 600 MiB ESP (PARTUUID `9aae0356-4274-46c0-8593-bbcd9769b22f`) and the retired Fedora 1 GiB ext4 (PARTUUID `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`) are removed — Fedora is confirmed retired. Before deletion both GPTs and the Windows, Arch, and Fedora ESPs are backed up cross-disk: the 2 TB GPT and Fedora ESP have a verified copy on the 512 GB Arch filesystem, while the 512 GB GPT and Windows/Arch ESPs have a verified copy on LinuxData. Serial/WWN/PARTUUID are then re-verified under the D2 pattern. After deletion the partition table is re-read to confirm the ~535.7 GiB contiguous freed extent and that the identities and bounds of Windows 500 GiB, Shared 150 GiB, and LinuxData 650 GiB are unchanged.

### D5. Provisioning the freed extent

The freed extent receives exactly two partitions: a 2 GiB NixOS ESP and a ~533.7 GiB LUKS2 volume, aligned to the extent boundaries so no adjacent partition shifts. Formatting happens only with **new** filesystem UUIDs — none are invented in advance; the generated UUIDs and filesystem declarations are merged into the curated `_hardware.nix` from the actual format output. The ESP is NixOS-owned; the Arch ESP is never shared.

### D6. Encryption, filesystem, and memory

LUKS2 with a passphrase only — no TPM enrollment in this install, so boot prompts for the passphrase and nothing depends on firmware attestation. Inside LUKS, Btrfs with `zstd:3` and `noatime`. Swap is zram only; no swap partition/file and no hibernation, matching the identity the readiness change already established.

### D7. Subvolume and mount layout

One Btrfs with the standard layout: `@root`→`/`, `@home`→`/home`, `@nix`→`/nix`, `@log`→`/var/log`, `@snapshots`→`/.snapshots`, plus `@home-cache`→the primary user's native home cache and `@containers`→the primary user's rootless container store. The two user-dependent targets are derived from topology and the native user options (home path, state paths) — no hardcoded username literals, consistent with the composition invariants the readiness change inherits.

### D8. Snapshot and data mounts

Snapper manages the root, home, and data Btrfs volumes. LinuxData keeps its current native-data mount — it is not resized, and its trailing ~27.3 GiB growth is explicitly out of scope. The Windows Shared NTFS mount keeps its existing `nofail` so a missing partition never blocks boot.

### D9. Firmware boot entries

The install registers a new NixOS firmware entry on the 2 TB disk; Windows and Arch entries remain untouched and selectable. The retired Fedora NVRAM entry is removed only after backup and provision verification — never speculatively, and never before NixOS boot is proven.

### D10. Install-day state migration

Before activation, the install provisions the root and primary-user sops age keys and NetworkManager profiles, and copies Tailscale state, Bluetooth pairing, and SSH host keys. Selected durable user state — browser profile, SSH, Syncthing, Grist, QMD/docs/projects, and anything else in the explicit inventory — is copied preserving ACLs, xattrs, and numeric IDs so ownership survives. Excluded: `~/.cache`, legacy standalone Home Manager/Nix profiles, and rootless container images (image activation reloads those after install). Secrets are copied in place and referenced by path; they never appear in any artifact. The login password is set after installation and before first boot.

### D11. Checkpoint discipline

Every destructive task carries the same four gates: precondition (identity + state assertions), backup (GPT, ESP, or prior state), verification of the result, and a rollback checkpoint. Rollback returns to the last checkpoint, so any failure strands the machine at a known-good state rather than mid-operation.

### D12. Install, verification, rollback

Installation runs from NixOS media: mount the new layout, merge the generated UUID/filesystem declarations into the curated `_hardware.nix`, build and install the flake, set the login password. Verification is sequential and explicit: firmware boot through the new entry, LUKS decryption, all mounts, network, NixOS and Home Manager generation, the desktop, secrets, and core services — then rollback to Arch is itself verified as the escape hatch.

### D13. Future scope: Arch retirement

Arch retirement — converting its 310 GiB root into an encrypted Btrfs backup receiver — is a deliberate future change. This install leaves the Arch root byte-for-byte untouched so Arch remains a working rollback path throughout.

## Risks / Trade-offs

- [NVMe reordering or a mismatched layout points a destructive command at the wrong disk] → the D2 pattern asserts serial/WWN/PARTUUID immediately before every destructive command and aborts on mismatch; no `/dev/nvmeX` is ever encoded.
- [Data loss on Windows/Shared/LinuxData if the freed-extent calculation drifts] → GPT backed up, partition table re-read after Fedora removal, and new partitions created only within the verified ~535.7 GiB extent; adjacent partition sizes asserted unchanged.
- [State migration gaps leave the new host half-configured] → the durable-state inventory is explicit, migration preserves ACLs/xattrs/numeric IDs, and each class is verified before activation; excluded classes are named so nothing is silently dropped.
- [Secret exposure in artifacts] → keys are copied in place and referenced by path; no secret value is ever written to an artifact.
- [Boot failure strands the machine without a fallback] → the new NixOS entry is verified first, then rollback to Arch is verified as the escape hatch; the Fedora NVRAM entry is removed only after both.
- \[Generated UUIDs diverge from what `_hardware.nix` declares\] → UUIDs are merged from actual format output into the curated file, never invented before formatting and never hand-edited to match an assumption.
- [UKI cleanup removes a path Arch still needs] → every UKI is backed up, the UKI matching the then-current kernel and Limine history are kept, and `limine.conf`/current kernel are re-checked immediately before cleanup.
- [TPM-less passphrase is less convenient at every boot] → accepted trade for a simpler, firmware-independent trust model in this install; TPM enrollment can be added later without re-provisioning.

## Migration Plan

1. **Gate:** run `nixos-bare-metal-readiness` strict validation and a full `nixosConfigurations.shrub` toplevel build; nothing destructive starts before both pass.
1. **Baseline:** record serial/WWN/PARTUUID for both disks; back up both GPTs and all three existing ESPs (Windows, Arch, and Fedora).
1. **Samsung cleanup:** re-inventory and back up every UKI, then move only UKIs that do not match the then-current kernel off the Arch ESP; keep the matching rescue UKI and Limine history.
1. **Fedora removal:** back up the GPT and Fedora ESP, re-verify identities, remove the two retired partitions, confirm the ~535.7 GiB contiguous extent and untouched neighbors.
1. **Provision:** create the 2 GiB NixOS ESP and ~533.7 GiB LUKS2 in the extent; format LUKS2 (passphrase) and Btrfs, create the full subvolume layout, mount it with `zstd:3`/`noatime`, and capture the new filesystem UUIDs.
1. **Merge:** fold the generated UUID and filesystem declarations into the curated `_hardware.nix` — no `/dev/nvmeX`.
1. **Stage:** boot NixOS media, mount the new layout, provision root/user age keys and NetworkManager profiles, and copy Tailscale/Bluetooth/SSH host keys plus selected user state with ACLs/xattrs/numeric IDs (excluding `~/.cache`, standalone profiles, and rootless container images).
1. **Install:** run `nixos-install` against the new ESP and LUKS root, set the login password before reboot, and verify firmware boot, decryption, mounts, network, NixOS and Home Manager generation, desktop, secrets, and core services; verify rollback to Arch; remove the Fedora NVRAM entry only after verification.
1. **Defer:** leave Arch retirement and its 310 GiB root conversion to a future change.
