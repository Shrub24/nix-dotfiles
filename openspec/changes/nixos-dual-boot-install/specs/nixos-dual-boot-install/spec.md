# nixos-dual-boot-install

## Purpose

Performs the install-day work deferred by `nixos-bare-metal-readiness`: permanently installs NixOS at the head of the 512 GB Samsung disk, replacing Windows, alongside an Arch install that stays bootable through a soak and is then deleted so the root can grow to the whole disk. Every disk is referenced by stable serial/WWN and every partition by PARTUUID or partlabel, never `/dev/nvmeX`; every destructive step is backed up, verified, and rollback-checkpointed, and the plan states what each checkpoint can restore. The data disk is never partitioned and `/home` is never moved.

## ADDED Requirements

### Requirement: Destructive tasks are gated on bare-metal readiness

No destructive disk task SHALL execute until `nixos-bare-metal-readiness` strict validation passes and a full build of the `nixosConfigurations.legion` toplevel succeeds; no install-day step SHALL substitute for that gate. Because the install target's mounts derive from the disko declaration, the toplevel that passes the gate SHALL be the configuration that is installed, and the flake SHALL NOT be edited between the gate and the install.

#### Scenario: Gate holds before any destructive step

- **WHEN** the install begins
- **THEN** no destructive disk task runs until strict validation and a full toplevel build pass
- **AND** no install-day step may replace the gate

#### Scenario: The installed system is the gated one

- **WHEN** the install runs
- **THEN** its source is a clean checkout whose `git rev-parse HEAD` equals the gate's recorded commit
- **AND** `git status --porcelain` is empty there and `nixos-generate-config` has not been run over the curated repository

### Requirement: The Windows backup is confirmed before the first delete

The install SHALL stop before any partition-table write, format or delete and require explicit confirmation that a verified backup of the Windows C: volume exists, because the extents that volume occupies become the LUKS root and no backup taken from this machine can restore that data.

#### Scenario: No delete precedes the confirmation

- **WHEN** the first destructive task is about to run
- **THEN** the Windows backup confirmation is recorded in the Execution Record
- **AND** no GPT write, format or delete has occurred before it

### Requirement: Disks and partitions are identified by stable identity only

The install SHALL reference disks by physical serial/WWN and partitions by PARTUUID or partlabel, SHALL NOT encode `/dev/nvmeX` numbering, and SHALL re-check serial, WWN, PARTUUID or partlabel immediately before each destructive command. The install target's disk SHALL be declared by-id, and firmware entries SHALL be matched by their baseline label and re-read identifier immediately before deletion.

#### Scenario: Destructive commands re-verify identity

- **WHEN** a destructive disk command is about to run
- **THEN** its target is confirmed by serial/WWN and by PARTUUID or partlabel immediately beforehand
- **AND** no `/dev/nvmeX` reference is written into the resulting configuration

#### Scenario: Firmware entries are identified before removal

- **WHEN** a stale NVRAM entry is to be removed
- **THEN** its label and identifier are re-read and matched against the baseline immediately beforehand
- **AND** only the entries pointing at deleted partitions are removed

### Requirement: NixOS replaces Windows at the head of the Samsung disk

The install SHALL delete the Windows ESP, MSR and NTFS volume in sectors 2048–343046143 and create in their place a 2 GiB FAT32 ESP with partlabel `disk-samsung-ESP` and a LUKS2 partition running to sector 343046143 with partlabel `disk-samsung-cryptroot`, SHALL leave the LUKS partition last so growing it later is one boundary move, and SHALL NOT alter the Arch root or Arch ESP partition identities, bounds or contents.

#### Scenario: Windows is replaced in place

- **WHEN** the target is provisioned
- **THEN** a 2 GiB EF00 ESP and a LUKS partition exist inside the extent the Windows partitions occupied
- **AND** the ESP carries the GPT EFI System Partition type GUID and both new partitions carry their declared partlabels

#### Scenario: Arch is untouched by provisioning

- **WHEN** the target is provisioned
- **THEN** the Arch root and Arch ESP retain their PARTUUIDs, start and end sectors
- **AND** Arch remains bootable through Limine

#### Scenario: The partition table is re-read without forcing it

- **WHEN** the kernel must re-read the table of the disk that holds the running root
- **THEN** the refresh is issued per partition (`partx -u`) rather than by re-reading the whole disk, which refuses while the running root is open
- **AND** a refresh that cannot complete stops the step and resumes after a reboot rather than being forced

### Requirement: The root volume is LUKS2 passphrase-encrypted btrfs

The install SHALL format LUKS2 with a passphrase only — no TPM enrolment — open it as `cryptroot`, format btrfs on `/dev/mapper/cryptroot`, and mount it with `zstd:3` and `noatime`. Swap SHALL be zram only, with no swap partition, no resume device and no hibernation.

#### Scenario: The root volume is encrypted and prompts

- **WHEN** the installed system boots
- **THEN** the root is decrypted from a passphrase prompt with no TPM dependency
- **AND** the root filesystem is btrfs on `/dev/mapper/cryptroot` with `zstd:3` and `noatime`
- **AND** swap is provided only by zram

### Requirement: The root subvolume set is `@`-based and names no user path

The install SHALL create `@`→`/`, `@nix`→`/nix`, `@cache`→`/var/cache`, `@log`→`/var/log`, `@tmp`→`/var/tmp`, `@images`→`/var/lib/libvirt/images`, and `@snapshots`→`/.snapshots` on the LUKS container, using `@` for the root subvolume throughout. `/home` SHALL NOT be created or moved on that container, `/home` and `/data` SHALL continue to resolve to the data disk as `storage.dataDisk` declares them, and no username literal SHALL appear in the layout.

#### Scenario: Subvolumes mount at their declared paths

- **WHEN** the NixOS host mounts the new root
- **THEN** each listed subvolume is mounted at its declared path with its declared options
- **AND** `/home` and `/data` resolve to the data disk, not to the LUKS container

#### Scenario: No shadow home is created

- **WHEN** the target is mounted for the install
- **THEN** the data disk's existing home subvolume is mounted at `/mnt/home`
- **AND** no home subvolume exists on the LUKS container

### Requirement: Root-disk mounts derive from the disk declaration

The NixOS host SHALL import the disko NixOS module and the host's disk declaration so that `fileSystems` for the root subvolumes and the ESP, and `boot.initrd.luks.devices.cryptroot`, are rendered from one declaration whose devices are a partlabel and a mapper name. The host's hardware module SHALL NOT declare a root-disk mount, and no install-day filesystem UUID SHALL be hand-edited into the configuration. The data disk SHALL remain outside that declaration, with its `/home` and `/data` mounts derived from `storage.dataDisk`.

#### Scenario: Root-disk mounts have one owner

- **WHEN** the NixOS host configuration is evaluated
- **THEN** `/`, `/nix`, `/var/cache`, `/var/log`, `/var/tmp`, `/var/lib/libvirt/images`, `/.snapshots` and `/boot` are rendered from the disk declaration by partlabel and mapper name
- **AND** the hardware module declares no root-disk mount and no root-disk UUID appears in the repository

#### Scenario: The data disk keeps its own source

- **WHEN** the NixOS host configuration is evaluated
- **THEN** `/home` and `/data` resolve to `storage.dataDisk` by its filesystem UUID
- **AND** no disko-rendered device is declared for them

### Requirement: The retired Fedora partitions are removed and their space left free

On the 2 TB SK hynix disk the install SHALL remove the retired Fedora ESP (PARTUUID `9aae0356-4274-46c0-8593-bbcd9769b22f`) and the retired Fedora ext4 (PARTUUID `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`) only after backing up that disk's GPT and ESP and re-verifying identities, SHALL create nothing in their place, and SHALL leave the freed extent unpartitioned for the eventual Windows reinstall. Windows 500 GiB, Shared 150 GiB and LinuxData 650 GiB SHALL keep their PARTUUIDs, partlabels and bounds.

#### Scenario: Fedora is removed and the extent left free

- **WHEN** the retired Fedora partitions are removed
- **THEN** the GPT and ESP were backed up and the identities re-verified first
- **AND** no partition is created in the freed extent
- **AND** Windows, Shared and LinuxData retain their PARTUUIDs, partlabels and start/end sectors

### Requirement: Root state is carried into the new root

Before the install the change SHALL copy `/etc/ssh/ssh_host_*`, `/var/lib/sops-nix/key.txt`, `/var/lib/tailscale`, `/var/lib/bluetooth`, and exactly the NetworkManager connection profiles on an explicit operator-supplied keep-list into the target root, preserving ownership and mode. It SHALL NOT carry ollama, docker or flatpak state, SHALL NOT migrate user data because the home subvolume does not move, and SHALL set the login password after installation and before the first boot without recording it.

#### Scenario: Machine identity survives the new root

- **WHEN** the new system boots
- **THEN** the SSH host keys, the sops age key, the tailnet node identity and the Bluetooth pairings are the ones carried from the previous root
- **AND** the copied NetworkManager profiles equal the recorded keep-list

#### Scenario: Whole-service state is deliberately left behind

- **WHEN** the target root is prepared
- **THEN** ollama, docker and flatpak state are absent from it
- **AND** user data is absent from it because `/home` is still the data disk's home subvolume

#### Scenario: Secrets are never disclosed

- **WHEN** install-day artifacts are produced
- **THEN** no secret material is exposed in them or in the Execution Record

### Requirement: The install runs from the running Arch system with media as fallback

The install SHALL run `nixos-install` from nixpkgs against the mounted target root while the Arch system is still running, copying the toplevel from the local store; it SHALL assert UEFI mode with writable EFI variables before starting, so the bootloader's firmware-variable write is known to be possible. NixOS media SHALL be documented as the fallback, and only the source of the closure SHALL differ between the two paths.

#### Scenario: The running system performs the install

- **WHEN** the install runs
- **THEN** it runs on the running Arch system into the mounted target with the toplevel copied from the local store
- **AND** the bootloader and firmware entry are installed on the new ESP

#### Scenario: The EFI variable write is known to work first

- **WHEN** the install is about to start
- **THEN** UEFI mode and writable `/sys/firmware/efi/efivars` have been asserted
- **AND** a failure of that assertion stops the install before it begins

### Requirement: Firmware entries for deleted partitions are removed

The install SHALL register a new NixOS firmware entry on the new ESP, SHALL remove the entries for the Windows ESP and the retired Fedora partition at install time, and SHALL keep the Arch entry until consolidation so Arch stays selectable.

#### Scenario: Boot entries follow what exists

- **WHEN** the install completes
- **THEN** a new NixOS entry exists and the Windows and Fedora entries are gone
- **AND** the Arch entry remains selectable

### Requirement: Every destructive task is checkpointed and its rollback is stated

Each destructive task SHALL have a precondition check, a backup, a verification of its result, and a rollback checkpoint, and the plan SHALL state what each checkpoint can restore. The consolidation group SHALL be identified as irreversible.

#### Scenario: Rollback returns to the last checkpoint

- **WHEN** a destructive task fails verification
- **THEN** the system returns to the last backup checkpoint before any further destructive work

#### Scenario: Irreversible steps are named

- **WHEN** the plan is read before consolidation
- **THEN** the growth of the root over the Arch and WinRE partitions is identified as irreversible
- **AND** it runs only on an explicit decision to end the soak, never as a failure response

### Requirement: Boot and rollback are verified before the soak

The install SHALL verify boot through the new firmware entry — decryption, every declared mount, network, the NixOS and Home Manager generation, the desktop, secrets, services, and the carried root state — and SHALL then verify that Arch still boots through Limine as the rollback path. The soak SHALL be recorded as a checkpoint before any consolidation work.

#### Scenario: Verified boot through the new firmware entry

- **WHEN** the install completes
- **THEN** NixOS boots with decryption, all declared mounts, network, generation, desktop, secrets and core services working
- **AND** the carried root state is verified from the booted system, not from the mount

#### Scenario: Arch remains the rollback path

- **WHEN** NixOS boot is verified
- **THEN** Arch still boots through Limine
- **AND** the soak checkpoint is recorded before consolidation begins

### Requirement: Consolidation grows the root to the whole disk

After the soak the install SHALL delete the Arch root, Arch ESP and WinRE partitions, grow the LUKS partition to the last sector of the disk, resize the container with `cryptsetup resize`, and grow the filesystem with `btrfs filesystem resize max`, leaving a 2 GiB ESP and a root owning the rest of the disk with a single NixOS firmware entry.

#### Scenario: The root takes the disk after the soak

- **WHEN** consolidation completes
- **THEN** the LUKS partition ends at the disk's last sector and the container and filesystem match it
- **AND** all seven subvolumes and their contents are intact and the only firmware entry for this disk is NixOS

### Requirement: The Windows reinstall is future scope

The install SHALL NOT create any partition for a Windows reinstall and SHALL NOT write into the freed SK hynix extent; reinstalling Windows there is deferred to a future change, as is growing LinuxData into its trailing free space and enrolling the LUKS root with a TPM.

#### Scenario: The freed extent stays free

- **WHEN** the install and consolidation complete
- **THEN** the freed SK hynix extent is still unpartitioned
- **AND** no task in this change created a partition for or wrote into it
