# Tasks — Dual-Boot NixOS Install

> Standing rule: every destructive task below is approval-gated (`notes: explicit user approval required immediately before execution`). If the DevOps specialist endpoint is
> unavailable, the parent stops before any destructive work — never substitute another
> automation. All disk targets resolve by serial/WWN and PARTUUID, never `/dev/nvmeX`.
> Execution evidence is appended to the Execution Record in this file; no ad-hoc task-state
> files are canonical.

## Group 1 — Readiness gate and immutable baseline (5)

- [ ] 1.1 Confirm every task in `nixos-bare-metal-readiness` is complete (all checkboxes
  `[x]`) and its final gate result is recorded.

  - criteria: no destructive install step proceeds before this holds
  - verify: readiness `tasks.md` fully checked; gate result captured in this file's Execution Record

- [ ] 1.2 Run strict OpenSpec validation (`openspec validate --all --strict`) and a full
  `nixosConfigurations.shrub` toplevel build (not `--no-build`) for the switchable host.

  - criteria: both green; no install-day step substitutes for this hard gate
  - verify: exit codes; toplevel out path recorded
  - depends: 1.1
  - delegate: BuildAgent

- [ ] 1.3 Capture the immutable baseline from live hardware: serial/WWN for both disks
  (Samsung `S6Z5NE0W500203`, SK hynix `ADC5N475011305I3I`), every PARTUUID, partition
  bounds, the then-current kernel (`uname -r`), and `limine.conf`; append it to the
  Execution Record with checksums.

  - verify: Execution Record lists both serials, both Fedora PARTUUIDs, and current kernel

- [ ] 1.4 Calculate the free extent from the live partition table (never assumed): confirm
  ~535.7 GiB contiguous once the two Fedora partitions are removed; record exact start/end
  sectors and the neighboring partition identities.

  - verify: computed extent matches ~535.7 GiB within alignment; neighbors are
    Windows/Shared/LinuxData
  - depends: 1.3

- [ ] 1.5 Produce durable backups of both GPTs and all three existing ESPs (Windows, Arch,
  and Fedora) with checksums, stored cross-disk: 2 TB GPT/Fedora ESP on the 512 GB Arch
  filesystem, and 512 GB GPT/Windows+Arch ESPs on LinuxData; record paths and checksums in
  the Execution Record.

  - criteria: every disk's partition-table backup has a verified copy on the other physical disk
  - verify: `sgdisk --backup` files + three ESP images present cross-disk with matching sha256 sums
  - depends: 1.3, 1.4

## Group 2 — Reversible Arch ESP cleanup (4)

- [ ] 2.1 Re-inventory every UKI on the Arch/Limine ESP and match each against the
  then-current kernel; flag the stale 7.1.3/7.1.5-era UKIs as unowned.

  - criteria: current-kernel UKI and Limine snapshot history identified for retention
  - verify: Execution Record lists each UKI with kernel match/mismatch
  - depends: 1.3

- [ ] 2.2 Verify the Arch ESP backup created in 1.5 contains every inventoried UKI and has
  matching checksums in the LinuxData cross-disk backup directory.

  - verify: every UKI present in backup; sha256 verified
  - depends: 2.1

- [ ] 2.3 Move only the UKIs that do not match the then-current kernel from the Arch ESP
  into the LinuxData cross-disk backup directory; keep the matching UKI as the independent
  Arch rescue and keep the deduplicated Limine snapshot history; re-check `limine.conf` and
  the current kernel immediately before the move.

  - criteria: only non-current UKIs moved; current kernel, `limine.conf`, and Limine history
    untouched
  - verify: ESP listing shows retained files; moved files present in backup
  - depends: 2.2
  - delegate: OpenDevopsSpecialist
  - notes: explicit user approval required immediately before execution

- [ ] 2.4 Verify Arch still boots via Limine and ESP free space grew; record the result.

  - criteria: Arch boots the current kernel through Limine
  - verify: Arch firmware entry selectable/boots; ESP free-space delta recorded
  - depends: 2.3

## Group 3 — Retired Fedora removal (4)

- [ ] 3.1 Re-check the 2 TB disk serial/WWN and both Fedora PARTUUIDs
  (`9aae0356-4274-46c0-8593-bbcd9769b22f`, `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`)
  immediately before the first removal command; abort on any mismatch.

  - criteria: identifiers match the assert-else-abort pattern
  - verify: `readlink`/`lsblk` assertions pass against the baseline in the Execution Record
  - depends: 1.5

- [ ] 3.2 Remove the retired Fedora 600 MiB ESP (PARTUUID `9aae0356-4274-46c0-8593-bbcd9769b22f`)
  only after backup and re-verification.

  - criteria: only that partition is deleted; GPT backup is current
  - verify: `lsblk`/`sgdisk` no longer list it; neighbors unchanged
  - depends: 3.1
  - delegate: OpenDevopsSpecialist
  - notes: explicit user approval required immediately before execution

- [ ] 3.3 Remove the retired Fedora 1 GiB ext4 (PARTUUID `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`)
  only after backup and re-verification.

  - criteria: only that partition is deleted
  - verify: partition gone; Windows/Shared/LinuxData PARTUUIDs and start/end sectors unchanged
  - depends: 3.2
  - delegate: OpenDevopsSpecialist
  - notes: explicit user approval required immediately before execution

- [ ] 3.4 Re-read the partition table and verify Windows (500 GiB), Shared (150 GiB), and
  LinuxData (650 GiB) identities and bounds unchanged, and the freed extent is ~535.7 GiB
  contiguous.

  - criteria: neighbors unchanged; contiguous extent confirmed
  - verify: partition-table diff vs the baseline in the Execution Record
  - depends: 3.3
  - notes: do not remove the Fedora NVRAM entry yet — that is gated in Group 6 after NixOS
    boot is proven

## Group 4 — Permanent storage provisioning (5)

- [ ] 4.1 Create exactly two partitions inside the verified extent: a 2 GiB NixOS ESP and a
  ~533.7 GiB Linux LUKS partition, aligned to extent boundaries; no `/dev/nvmeX` reference.

  - criteria: new partitions lie only within the recorded extent sectors; neighbors untouched
  - verify: partition table shows the two new partitions inside extent bounds
  - depends: 3.4
  - delegate: OpenDevopsSpecialist
  - notes: explicit user approval required immediately before execution

- [ ] 4.2 Verify the new partitions sit inside the recorded extent and Windows/Shared/LinuxData
  bounds are unchanged.

  - verify: `lsblk`/`sgdisk` bounds match the recorded extent sectors
  - depends: 4.1

- [ ] 4.3 Format the LUKS partition: LUKS2 with a passphrase only (no TPM enrollment), then
  Btrfs; capture the actual new filesystem UUIDs from the format output (never invented).

  - criteria: LUKS2 passphrase only; no TPM; UUIDs recorded from actual format output
  - verify: `cryptsetup luksDump` shows LUKS2; `btrfs filesystem show` UUID captured
  - depends: 4.2
  - delegate: OpenDevopsSpecialist
  - notes: explicit user approval required immediately before execution

- [ ] 4.4 Create the subvolume layout on the Btrfs: `@root`, `@home`, `@nix`, `@log`,
  `@snapshots`, `@home-cache`, `@containers`; user-dependent targets derived from topology,
  no hardcoded usernames.

  - criteria: all seven subvolumes exist
  - verify: `btrfs subvolume list` shows the full layout
  - depends: 4.3

- [ ] 4.5 Mount the layout with `zstd:3`/`noatime`; record actual UUIDs and mount options
  in the Execution Record; never hardcode `/dev/nvmeX`.

  - verify: `findmnt` shows each subvolume with `zstd:3,noatime`
  - depends: 4.4

## Group 5 — Configuration and state staging (6)

- [ ] 5.1 Update the curated `_hardware.nix` from the actual captured UUIDs and
  topology-derived user paths (no `/dev/nvmeX`, no username literals).

  - criteria: file references only real UUIDs/by-id identities and topology values
  - verify: exhaustive search for `/dev/nvmeX` and username literals returns nothing
  - depends: 4.5
  - delegate: CoderAgent

- [ ] 5.2 Re-run the readiness gates after the metadata edit: strict validation and a full
  toplevel eval/build still pass.

  - verify: `nix build .#nixosConfigurations.shrub.config.system.build.toplevel`,
    `nix flake check --no-build --no-write-lock-file`, and
    `openspec validate --all --strict` all green
  - depends: 5.1
  - delegate: BuildAgent

- [ ] 5.3 Stage the root and primary-user sops age keys and NetworkManager profiles before
  activation; keys referenced by path, values never written to artifacts.

  - criteria: keys/profiles present at declared paths; no secret value in any artifact
  - verify: paths resolve; log/diff scan shows no secret material
  - depends: 4.5

- [ ] 5.4 Copy Tailscale state, Bluetooth pairing, and SSH host keys into the staged target
  preserving ownership.

  - verify: files present with ownership/ACLs intact
  - depends: 5.3

- [ ] 5.5 Inventory and copy selected durable user state (browser profile, SSH, Syncthing,
  Grist, QMD/docs/projects) preserving ACLs, xattrs, and numeric IDs; exclude `~/.cache`,
  legacy standalone Home Manager/Nix profiles, and rootless container images.

  - criteria: included classes copied with numeric IDs intact; excluded classes absent
  - verify: `rsync -aHAX --numeric-ids`/`cp --preserve` check plus explicit absence check of excluded classes
  - depends: 5.3, 5.4
  - delegate: OpenDevopsSpecialist

- [ ] 5.6 Verify no secret values enter logs, diffs, or artifacts from the staging work.

  - criteria: secret scan of artifacts and the change diff is clean
  - verify: grep of artifacts + review of the diff
  - depends: 5.3, 5.4, 5.5
  - delegate: CodeReviewer

## Group 6 — Install and acceptance (6)

- [ ] 6.1 Install from NixOS media into the mounted target: build and run `nixos-install`
  against the new ESP and LUKS root with the merged `_hardware.nix`.

  - criteria: install completes; bootloader registered on the NixOS-owned ESP
  - verify: `nixos-install` exit 0; ESP populated; new firmware entry present
  - depends: 5.1, 5.3, 5.4, 5.5
  - delegate: OpenDevopsSpecialist
  - notes: explicit user approval required immediately before execution

- [ ] 6.2 Set the user login password after installation and before first reboot.

  - verify: password set on the installed target
  - depends: 6.1

- [ ] 6.3 Boot through the new NixOS firmware entry and verify: LUKS decryption, all
  mounts/subvolumes, network, NixOS + embedded Home Manager generation, desktop, secrets,
  Syncthing identity, Niks3, tailnet services, Snapper, and firmware/GPU/audio.

  - criteria: every item in the verification checklist passes; generation shows embedded HM
  - verify: `findmnt`, generations, network, and service checks recorded
  - depends: 6.2

- [ ] 6.4 Verify Windows and Arch firmware boots still work and Arch remains the verified
  rollback path.

  - verify: firmware menu shows Windows and Arch; both boot; Arch rollback confirmed
  - depends: 6.3

- [ ] 6.5 Remove the retired Fedora NVRAM entry only after backup and provision verification,
  and only after NixOS boot is proven.

  - criteria: Fedora entry removed; Windows/Arch/NixOS entries intact
  - verify: `efibootmgr` listing recorded
  - depends: 6.3, 6.4
  - delegate: OpenDevopsSpecialist
  - notes: explicit user approval required immediately before execution

- [ ] 6.6 Record the soak checkpoint: verified state, generation, and rollback instructions
  in the Execution Record.

  - verify: Execution Record contains soak details
  - depends: 6.5

## Group 7 — Handoff and deferred scope (3)

- [ ] 7.1 Update operator docs with actual UUIDs, backup paths, and install/verification
  results.

  - delegate: DocWriter
  - depends: 6.6

- [ ] 7.2 Run strict OpenSpec validation (`openspec validate --all --strict`) and repository
  checks; all green.

  - verify: validation and repo checks pass
  - depends: 7.1
  - delegate: BuildAgent

- [ ] 7.3 Explicitly record deferred scope: Arch root and retirement untouched, LinuxData
  trailing ~27.3 GiB growth deferred, and the future encrypted backup receiver out of scope.

  - criteria: no task in this change touches the Arch root or LinuxData bounds
  - verify: docs state the deferred items
  - depends: 7.2

## Execution Record

Populate during apply with baseline identifiers, backup paths/checksums, generated UUIDs,
validation results, and rollback checkpoints. Never record secret values.
