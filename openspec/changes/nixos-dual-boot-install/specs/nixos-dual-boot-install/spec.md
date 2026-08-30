# nixos-dual-boot-install

## Purpose

Performs the install-day work deferred by `nixos-bare-metal-readiness`: permanently installs NixOS as a third, independently bootable OS on the 2 TB SK hynix disk alongside Windows and Arch — only the dual-boot coexistence with Arch is a temporary soak. Every disk is referenced by stable serial/WWN and every partition by PARTUUID or filesystem UUID, never `/dev/nvmeX`; every destructive step is backed up, verified, and rollback-checkpointed. Windows and Arch stay bootable and their partitions untouched; Arch retirement is future scope.

## ADDED Requirements

### Requirement: Destructive tasks are gated on bare-metal readiness

No destructive disk task SHALL execute until `nixos-bare-metal-readiness` strict validation passes and a full build of the `nixosConfigurations.shrub` toplevel succeeds; no install-day step SHALL substitute for that gate.

#### Scenario: Gate holds before any destructive step

- **WHEN** the install begins
- **THEN** no destructive disk task runs until strict validation and a full toplevel build pass
- **AND** no install-day step may replace the gate

### Requirement: Disks and partitions are identified by stable identity only

The install SHALL reference disks by physical serial/WWN and partitions by PARTUUID or filesystem UUID, SHALL NOT encode `/dev/nvmeX` numbering, and SHALL re-check serial, WWN, and PARTUUID immediately before each destructive command.

#### Scenario: Destructive commands re-verify identity

- **WHEN** a destructive disk command is about to run
- **THEN** its target is confirmed by serial/WWN and PARTUUID immediately beforehand
- **AND** no `/dev/nvmeX` reference is written into the resulting configuration

### Requirement: Windows and Arch remain untouched on the Samsung disk

The 512 GB Samsung disk SHALL keep Windows boot, the NTFS data partition, the Arch root, and the Arch/Limine ESP intact, with the sole exception of the reversible backup-and-move of stale unowned UKIs.

#### Scenario: Windows and Arch stay bootable

- **WHEN** the install completes
- **THEN** the Windows, NTFS, Arch root, and Arch ESP partitions are unchanged apart from the stale-UKI cleanup
- **AND** Windows and Arch remain independently bootable

### Requirement: Stale Arch UKI cleanup is backed up and verified

The install SHALL re-inventory and back up every Arch UKI before cleanup, SHALL move only UKIs that do not match the then-current kernel, SHALL keep the matching UKI as an independent Arch rescue, SHALL keep the deduplicated Limine snapshot history, and SHALL re-assert the Samsung disk serial/WWN and the baseline-recorded Arch ESP PARTUUID and re-check `limine.conf` and the current kernel immediately before cleanup.

#### Scenario: UKIs leave the ESP only after backup

- **WHEN** the Arch ESP cleanup runs
- **THEN** every UKI is backed up before any non-current UKI is moved off the ESP
- **AND** the UKI matching the then-current kernel and the Limine history remain, and the Samsung/Arch-ESP identity, `limine.conf`, and the current kernel were re-checked first

### Requirement: Retired Fedora partitions are removed with backup and verification

On the 2 TB SK hynix disk the install SHALL remove the retired Fedora 600 MiB ESP (PARTUUID `9aae0356-4274-46c0-8593-bbcd9769b22f`) and the retired Fedora 1 GiB ext4 (PARTUUID `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`) only after backing up both GPTs and the Windows, Arch, and Fedora ESPs cross-disk and re-verifying serial, WWN, and PARTUUID. Windows 500 GiB, Shared 150 GiB, and LinuxData 650 GiB SHALL keep their partition identities and bounds; LinuxData may gain only the dedicated backup directory.

#### Scenario: Fedora partitions are backed up before removal

- **WHEN** the retired Fedora partitions are removed
- **THEN** both GPTs and all three existing ESPs are backed up and the identifiers re-verified first
- **AND** Windows, Shared, and LinuxData retain their identifiers and start/end sectors, and the freed extent is the expected ~535.7 GiB contiguous space

### Requirement: New NixOS ESP and LUKS volume are provisioned in the freed extent

The install SHALL create a 2 GiB FAT32 NixOS ESP with the EFI System Partition type GUID (`C12A7328-F81F-11D2-BA4B-00A0C93EC93B`, EF00) and a ~533.7 GiB LUKS2-encrypted Btrfs volume in the exact freed extent, SHALL format the ESP FAT32, SHALL format the LUKS2 container (passphrase only), record its LUKS-header UUID via `cryptsetup luksUUID`, open it as `cryptroot`, and format Btrfs on `/dev/mapper/cryptroot`, SHALL capture the actual filesystem UUIDs from format output, SHALL replace the existing Arch root and ESP declarations in the curated `_hardware.nix` with the actual generated metadata — the new ESP UUID mounted at `/boot`, the actual LUKS-header UUID as `boot.initrd.luks.devices.cryptroot.device = "/dev/disk/by-uuid/<actual-LUKS-UUID>"`, and the Btrfs UUID with all seven subvolume mounts — while preserving the Shared and LinuxData declarations, and SHALL NOT encode `/dev/nvmeX` or invent UUIDs. LUKS2 SHALL be passphrase-protected with no TPM enrollment; Btrfs SHALL use `zstd:3` and `noatime`.

#### Scenario: New volumes are created from the freed extent

- **WHEN** provisioning runs
- **THEN** a 2 GiB NixOS ESP and a ~533.7 GiB LUKS2 Btrfs volume exist in the exact freed extent
- **AND** the ESP is FAT32 with the EF00 type GUID, mounted at `/mnt/boot` during install, with its actual UUID captured
- **AND** the LUKS container is opened as `cryptroot` with Btrfs on `/dev/mapper/cryptroot`
- **AND** the Windows, Shared, and LinuxData partition sizes are unchanged

#### Scenario: Generated metadata replaces the old Arch declarations

- **WHEN** the curated `_hardware.nix` is updated
- **THEN** it declares the new ESP UUID at `/boot`, the actual LUKS-header UUID (from `cryptsetup luksUUID`) under `boot.initrd.luks.devices.cryptroot`, and the Btrfs UUID with all seven mounts
- **AND** the Shared and LinuxData declarations are preserved and no `/dev/nvmeX` or invented UUID appears

### Requirement: Subvolume and mount layout is fixed and user-derived

The install SHALL create `@root`→`/`, `@home`→`/home`, `@nix`→`/nix`, `@log`→`/var/log`, `@snapshots`→`/.snapshots`, `@home-cache`→`/home/${primaryUser.name}/.cache`, and `@containers`→`/home/${primaryUser.name}/.local/share/containers`. User-dependent paths SHALL be topology-derived, not hardcoded usernames. `topology.hosts.arch` SHALL remain unchanged during dual boot — Arch stays an active host — with its rename deferred to the Arch-retirement scope, while `nixosConfigurations.shrub` and `networking.hostName = "shrub"` are unchanged.

#### Scenario: Subvolumes mount at their declared paths

- **WHEN** the NixOS host mounts the new root
- **THEN** each listed subvolume is mounted at its declared path
- **AND** the home cache and container store paths resolve to the topology-derived `/home/${primaryUser.name}/.cache` and `/home/${primaryUser.name}/.local/share/containers`

### Requirement: NixOS uses its own ESP and preserves firmware boot entries

The install SHALL use a new NixOS-owned ESP and SHALL NOT share the Arch ESP. Windows and Arch firmware boot entries SHALL remain, and the retired Fedora NVRAM entry SHALL be removed only after backup and provision verification.

#### Scenario: Boot entries remain independent

- **WHEN** the install registers NixOS boot
- **THEN** a new NixOS firmware entry exists on the 2 TB disk
- **AND** Windows and Arch remain selectable, and the Fedora entry is removed only after verification

### Requirement: Install-day state is provisioned before first boot

Before activation the install SHALL provision the root and primary-user sops age keys and NetworkManager profiles, and SHALL copy Tailscale state, Bluetooth pairing, SSH host keys, and selected durable user state — browser profile, SSH, Syncthing, Grist, QMD/docs/projects — preserving ACLs, xattrs, and numeric IDs. The install SHALL exclude `~/.cache`, legacy standalone Home Manager/Nix profiles, and rootless container images, and SHALL set the login password after installation and before first boot via `nixos-enter --root /mnt -c 'passwd <topology-derived-user>'` without recording it.

#### Scenario: Durable state survives activation

- **WHEN** the new system activates
- **THEN** the provisioned keys and profiles and the copied Tailscale, Bluetooth, and SSH host key state are present
- **AND** the selected user state is migrated with ACLs, xattrs, and numeric IDs while the excluded classes are absent
- **AND** the login password is set before the first boot

#### Scenario: Secrets are never disclosed

- **WHEN** install-day artifacts are produced
- **THEN** no secret material is exposed in them

### Requirement: Every destructive task is checkpointed

Each destructive task SHALL have a precondition check, a backup, a verification of its result, and a rollback checkpoint, and rollback SHALL return to the last checkpoint.

#### Scenario: Rollback returns to the last checkpoint

- **WHEN** a destructive task fails verification
- **THEN** the system returns to the last backup checkpoint before any further destructive work

### Requirement: Install, boot, and rollback verification

The install SHALL run from NixOS media against the new ESP and LUKS root. Before the media pass, the generated metadata SHALL be committed and pushed, then validated with strict checks and a full toplevel build from the Arch checkout. The media pass SHALL clone and check out the recorded pushed SHA at `/mnt/etc/nixos` in detached state, verifying `git rev-parse HEAD` equals it and `git status --porcelain` is empty before install — never running `nixos-generate-config` over the curated repo — and SHALL install with `nixos-install --root /mnt --flake /mnt/etc/nixos#shrub`, building into the target store. The install SHALL verify firmware boot, decryption, mounts, network, the NixOS and Home Manager generation, the desktop, secrets, and core services, and SHALL verify rollback to Arch.

#### Scenario: Verified boot through the new firmware entry

- **WHEN** the install completes
- **THEN** NixOS boots through the new firmware entry with working decryption, mounts, network, generation, desktop, secrets, and core services
- **AND** the booted system was built from the exact validated commit checked out clean at `/mnt/etc/nixos`
- **AND** rollback to Arch is verified

#### Scenario: Arch remains the rollback path

- **WHEN** NixOS boot is verified
- **THEN** Windows and Arch remain bootable and Arch remains the verified rollback path

### Requirement: Arch retirement is future scope

The install SHALL NOT retire Arch and SHALL NOT reformat its 310 GiB root; converting it into an encrypted Btrfs backup receiver is deferred to a future change.

#### Scenario: Arch root stays untouched

- **WHEN** the install completes
- **THEN** the Arch root partition is untouched
- **AND** no Arch retirement or re-formatting has occurred
