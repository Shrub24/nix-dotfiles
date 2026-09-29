# Tasks — Dual-Boot NixOS Install

> Standing rule: every destructive task below is approval-gated (`notes: explicit user approval required immediately before execution`), and every disk target resolves by serial/WWN, PARTUUID or partlabel — never `/dev/nvmeX`. All disk work runs from the running Arch system unless a task says otherwise; execution evidence is appended to the Execution Record in this file, and no ad-hoc task-state file is canonical.

## Group 1 — Gate, Windows backup, baseline (5)

- [ ] 1.1 Confirm every task in `nixos-bare-metal-readiness` is complete and its
      strict validation plus full `nixosConfigurations.legion` toplevel build
      pass from the Arch checkout (not `--no-build`), with at least 40 GiB free
      on the Arch root before the build starts.

  - criteria: both green; no destructive install step proceeds before this holds
  - verify: exit codes; `df -h /nix`; toplevel out path recorded in the Execution Record
  - refs: design D1, D5

- [ ] 1.2 **Stop here and confirm the Windows backup.** The operator states where
      the Windows C: backup is, when it was taken, and that it has been verified.
      No delete, format, or partition-table write runs before this is recorded.

  - criteria: the Windows backup is confirmed and recorded before the first destructive command
  - verify: Execution Record holds the confirmation; no GPT write has occurred
  - refs: design D4
  - notes: this is the only irreversible data loss in the change — the Windows
    extents become the LUKS root, and no backup taken from this machine can restore them

- [ ] 1.3 Capture the immutable baseline from live hardware: serial/WWN for both
      disks (Samsung `S6Z5NE0W500203`, SK hynix `ADC5N475011305I3I`), every
      PARTUUID and partlabel, every partition's start/end sector, the filesystem
      UUIDs of LinuxData and the Shared NTFS volume, `uname -r`, `limine.conf`,
      and the `efibootmgr` listing with each entry's label and id.

  - criteria: identifiers and bounds recorded before any change, with a checksum of the capture
  - verify: Execution Record lists both serials plus the Windows, Fedora, Arch and LinuxData identities

- [ ] 1.4 Produce durable cross-disk backups of both GPTs and all three existing
      ESPs (Windows, Arch and Fedora) with sha256 checksums: the Samsung GPT and
      its Windows and Arch ESP images into `/data/install-backups/`, and the SK
      hynix GPT and Fedora ESP image into the Arch filesystem's
      `/root/install-backups/`. Verify every image before relying on it.

  - criteria: each disk's partition-table backup has a verified copy on the other physical disk
  - verify: `sgdisk --backup` files and three ESP images present cross-disk with matching sums
  - refs: design D4, D12

- [ ] 1.5 Assert the machine is booted in UEFI mode with writable
      `/sys/firmware/efi/efivars`, that no partition of the Samsung is mounted or
      held open by a process, and that the partitions this change rewrites
      (p1–p3) are the Windows ones by reading their PARTUUIDs.

  - criteria: efivars writable; nothing in the target extent is in use
  - verify: `mountpoint`/`lsblk` checks and partlabel resolution recorded
  - depends: 1.3
  - refs: design D2, D5

## Group 2 — Samsung: Windows removed, root provisioned (5)

- [ ] 2.1 Re-assert the Samsung serial/WWN and the Windows ESP, MSR and C:
      PARTUUIDs (`2193a654-…`, `031ea351-…`, `9ce9fe67-…`, full values from the
      baseline), then delete those three partitions. Create in their place a
      2 GiB ESP at sectors 2048–4196351 with the EFI System Partition type GUID
      (`C12A7328-F81F-11D2-BA4B-00A0C93EC93B`) and partlabel `disk-samsung-ESP`,
      and a Linux partition at sectors 4196352–343046143 with partlabel
      `disk-samsung-cryptroot`. Re-read the table with `partx -u` (never
      `partprobe`: `BLKRRPART` refuses while the running root is open).

  - criteria: fresh identity assertion passes immediately before the write; only p1–p3 deleted; both new partitions inside the recorded extent with those exact partlabels
  - verify: `sgdisk --print`/`lsblk` show the two partitions with their partlabels; `/dev/disk/by-partlabel/disk-samsung-ESP` and `-cryptroot` resolve
  - depends: 1.2, 1.5
  - notes: explicit user approval required immediately before execution
  - refs: design D2, D3

- [ ] 2.2 If `partx -u` cannot refresh the table because a partition of the disk is
      open, reboot into Arch and resume here — the re-read is not allowed to
      become a reason to force anything.

  - criteria: the new partition nodes exist and resolve by partlabel
  - verify: `lsblk` shows both new partitions; no step in this group was retried against a stale table
  - depends: 2.1
  - refs: design D5

- [ ] 2.3 Verify the repartition: the Arch root and Arch ESP (p5, p6) keep their
      PARTUUIDs, start and end sectors exactly as baselined, and the disk's total
      sector count is unchanged.

  - criteria: p5 and p6 byte-identical in the table; nothing outside the target extent changed
  - verify: partition-table diff against the baseline in the Execution Record
  - depends: 2.2

- [ ] 2.4 Format the target: FAT32 on the new ESP; LUKS2 with a passphrase only (no
      TPM) on `disk-samsung-cryptroot`, opened as `cryptroot`; btrfs on
      `/dev/mapper/cryptroot`. Record the LUKS-header UUID (`cryptsetup luksUUID`)
      and the btrfs UUID from the format output in the Execution Record — they are
      evidence, not configuration, because no mount in the system names them.

  - criteria: fresh identity assertion before formatting; LUKS2 passphrase only; no TPM; no UUID written into any repository file
  - verify: `cryptsetup luksDump` shows LUKS2; `/dev/mapper/cryptroot` present; `blkid` output recorded
  - depends: 2.3
  - notes: explicit user approval required immediately before execution
  - refs: design D6, D8

- [ ] 2.5 Create the subvolume set on the new btrfs — `@`, `@nix`, `@cache`,
      `@log`, `@tmp`, `@images`, `@snapshots` — and mount the layout at `/mnt`
      with `zstd:3`, `noatime`, `ssd`, `discard=async`, `space_cache=v2`; mount
      the ESP at `/mnt/boot`, and the data disk's existing `@home` and `@data` at
      `/mnt/home` and `/mnt/data` with the options `_storage.nix` declares, so the
      install writes no shadow home into the root subvolume.

  - criteria: exactly those seven subvolumes exist; no `@home` is created on the LUKS; `/home` and `/data` resolve to LinuxData
  - verify: `btrfs subvolume list` and `findmnt` output recorded
  - depends: 2.4
  - refs: design D7

## Group 3 — SK hynix: retired Fedora removal (3)

- [ ] 3.1 Re-assert the SK hynix serial/WWN and both Fedora PARTUUIDs
      (`9aae0356-4274-46c0-8593-bbcd9769b22f` and
      `16921d6b-a8b7-4f04-8fdf-44ebc6d36acc`), then delete the retired Fedora ESP
      and the retired Fedora ext4. Create nothing in their place.

  - criteria: fresh identity assertion before each deletion; only those two partitions deleted; the freed extent left unpartitioned
  - verify: `lsblk`/`sgdisk` no longer list them; freed extent recorded for the future Windows reinstall
  - depends: 1.4, 2.5
  - notes: explicit user approval required immediately before execution
  - refs: design D9

- [ ] 3.2 Verify Windows 500 GiB, Shared 150 GiB and LinuxData 650 GiB keep their
      PARTUUIDs, partlabels and bounds, and that `/data` and `/home` are still
      mounted from the same filesystem UUID.

  - criteria: every kept partition unchanged; `findmnt /home /data` shows `47fa5ee2-…`
  - verify: partition-table diff against the baseline; `findmnt` output recorded
  - depends: 3.1

- [ ] 3.3 Copy the SK hynix GPT and Fedora ESP backup from `/root/install-backups/`
      into the new root's `/root/install-backups/`, so the only copy of that
      disk's table is not destroyed when Arch is deleted after the soak.

  - criteria: the backup exists on both disks; checksums match the originals
  - verify: sha256 comparison recorded
  - depends: 3.1, 2.5
  - refs: design D12

## Group 4 — Root state carry, then the export checkout (4)

- [ ] 4.1 Copy the root state that identifies the machine into `/mnt`, preserving
      ownership and mode: `/etc/ssh/ssh_host_*`, `/var/lib/sops-nix/key.txt`,
      `/var/lib/tailscale`, `/var/lib/bluetooth`.

  - criteria: all four present at identical relative paths with ownership and modes intact
  - verify: `ls -l` and checksum comparison per item; fleet SSH host key matches the pinned ed25519 key
  - depends: 2.5
  - refs: design D11

- [ ] 4.2 Copy exactly the NetworkManager profiles on the operator's keep-list from
      `/etc/NetworkManager/system-connections/` into `/mnt`, and record the list
      in the Execution Record.

  - criteria: the copied set equals the keep-list; the list is explicit before the copy runs, not "all of them"
  - verify: file-by-file listing of both source selection and destination
  - depends: 4.1
  - refs: design D11

- [ ] 4.3 Verify no state outside the carried set was copied and no secret value
      reached an artifact: the excluded service state (ollama, docker, flatpak) is
      absent from `/mnt`, and neither the Execution Record nor any log in the
      working tree holds key material.

  - criteria: excluded classes absent; artifact scan clean
  - verify: absence checks plus a scan of the change's own artifacts
  - depends: 4.1, 4.2

- [ ] 4.4 Clone the repository and check out the recorded gate SHA (task 1.1) into a
      scratch directory root can read, and verify it is clean before the install.

  - criteria: exact SHA, detached, no local modifications; the flake is not edited after the gate
  - verify: `git rev-parse HEAD` equals the recorded SHA and `git status --porcelain` is empty
  - depends: 1.1, 2.5
  - refs: design D5

## Group 5 — Install from the running Arch system (4)

- [ ] 5.1 Install into the mounted target from the running Arch system, with a scratch
      checkout of the recorded SHA as the flake path:
      `sudo nix run nixpkgs#nixos-install-tools -- --root /mnt --flake /root/legion-export#legion --no-root-passwd`.
      The toplevel is copied from the local store through the script's `auto`
      substituter, so expect copies and no rebuild; record the target store's
      size before and after.

  - criteria: install completes; bootloader installed on the new ESP; no rebuild of the toplevel
  - verify: exit 0; `/mnt/boot` populated with the generation's kernels; `/mnt/nix/var/nix/profiles/system` set
  - depends: 2.5, 4.4
  - notes: explicit user approval required immediately before execution
  - refs: design D5

- [ ] 5.2 Set the primary-user login password after installation and before the
      first reboot: `nixos-enter --root /mnt -c 'passwd <topology-derived-user>'`.
      The password is never recorded.

  - criteria: password set on the installed target; root left locked by `--no-root-passwd`
  - verify: password change succeeds interactively; no password material in artifacts
  - depends: 5.1

- [ ] 5.3 Remove the firmware entries that point at what this change deleted:
      re-read `efibootmgr`, match the `Windows Boot Manager` and `Fedora` entries
      against the baseline ids, and delete those two only. Keep `Limine`.

  - criteria: the two entries gone; the Limine entry and the new NixOS entry intact
  - verify: `efibootmgr` listing recorded before and after
  - depends: 3.1, 5.1
  - notes: explicit user approval required immediately before execution
  - refs: design D10

- [ ] 5.4 Fall back to NixOS media only if the running-system path is unavailable: in
      that case clone the recorded SHA to `/mnt/etc/nixos`, verify it clean, and
      run the same `nixos-install` from the media — accepting that the closure is
      built inside the installer's store instead of copied from the local one.

  - criteria: the same configuration and the same checkout SHA, whichever path ran
  - verify: `git rev-parse HEAD` at the install source equals the recorded SHA
  - depends: 5.1
  - refs: design D5

## Group 6 — Boot verification and soak (4)

- [ ] 6.1 Boot through the new NixOS firmware entry and verify: LUKS passphrase
      prompt, all seven root subvolumes mounted at their declared paths, `/home`
      and `/data` on LinuxData, `/boot` on the new ESP by partlabel, network,
      Home Manager generation, desktop session, secrets decryption, tailnet
      identity, Syncthing identity, Snapper, and the NVIDIA/iGPU stack.

  - criteria: every item passes; the mounts match the disko declaration exactly
  - verify: `findmnt`, `systemctl --failed`, generation listing and service checks recorded
  - depends: 5.2, 5.3
  - refs: design D7, D8, D11

- [ ] 6.2 Verify Arch still boots through Limine and remains the rollback path, and
      that the freed SK hynix extent is still free.

  - criteria: Arch boots the current kernel; rollback path confirmed
  - verify: firmware menu shows Limine; Arch boots; `sgdisk --print` on the SK hynix recorded
  - depends: 6.1

- [ ] 6.3 Verify the same mounted root state that the plan carried is live: the
      fleet's pinned SSH host key, the sops age key decrypting system secrets, the
      tailnet node identity, Bluetooth pairings, and the NetworkManager profiles on
      the keep-list.

  - criteria: all five classes verified from the booted system, not from the mount
  - verify: `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`, sops-rendered path present, `tailscale status`, `bluetoothctl devices`, `nmcli connection show`
  - depends: 6.1

- [ ] 6.4 Record the soak checkpoint: verified state, generation, what rollback would
      do, and the explicit statement that the post-soak group has not run.

  - criteria: the Execution Record names the checkpoint before any post-soak work
  - verify: record present and dated
  - depends: 6.3
  - refs: design D13

## Group 7 — Post-soak consolidation (5)

- [ ] 7.1 Confirm the soak is being ended deliberately — NixOS has been the daily
      system through the soak, Arch is still bootable, and the operator accepts
      that the next group destroys it.

  - criteria: explicit operator decision recorded; not triggered by a failure
  - verify: Execution Record holds the decision
  - depends: 6.4
  - notes: explicit user approval required immediately before execution
  - refs: design D12, D13

- [ ] 7.2 Re-assert the Samsung serial/WWN and the Arch root, Arch ESP and WinRE
      PARTUUIDs (`e33cb524-…`, `1a2c5601-…`, `b5c0d8da-…`), then delete p5, p6
      and p4, and re-read the table with `partx -u`.

  - criteria: fresh identity assertion before each deletion; the ESP and LUKS partitions make no other change
  - verify: `sgdisk --print` recorded; only the ESP and the LUKS partition remain
  - depends: 7.1
  - notes: explicit user approval required immediately before execution

- [ ] 7.3 Grow the LUKS partition from sector 4196352 to the last sector of the disk
      (474.94 GiB) and re-read the table.

  - criteria: the partition's end equals the disk's last sector; the ESP is unchanged
  - verify: `sgdisk --print` plus `blockdev --getsz` comparison recorded
  - depends: 7.2

- [ ] 7.4 Grow the container and the filesystem it holds: `cryptsetup resize
cryptroot`, then `btrfs filesystem resize max /` from the booted system, and
      verify the root filesystem reports the grown size with all seven subvolumes
      intact.

  - criteria: the mapper and the btrfs both match the partition; subvolumes and their data unchanged
  - verify: `cryptsetup status cryptroot`, `btrfs filesystem usage /`, `btrfs subvolume list /`
  - depends: 7.3

- [ ] 7.5 Remove the `Limine` firmware entry, verify the new NixOS entry is the only
      one left for this disk, and record the final layout.

  - criteria: Limine entry gone; NixOS entry intact
  - verify: `efibootmgr` listing recorded
  - depends: 7.4
  - refs: design D13

## Group 8 — Handoff and deferred scope (3)

- [ ] 8.1 Update operator documentation with the actual UUIDs, partlabels, backup
      paths, the install path that ran, and the verification results.

  - depends: 7.5

- [ ] 8.2 Run strict OpenSpec validation and repository checks; all green.

  - verify: `openspec validate --all --strict` and `nix flake check --no-build --no-write-lock-file`
  - depends: 8.1

- [ ] 8.3 Record deferred scope explicitly: the eventual Windows reinstall into the
      freed SK hynix extent, LinuxData's trailing ~27.3 GiB, and TPM enrolment for
      the LUKS root. No task in this change partitions, mounts or writes into that
      freed extent.

  - criteria: the deferred items are stated where the follow-up work will look for them
  - verify: docs state them; no task above touches the freed extent
  - depends: 8.2

## Execution Record

Populate during apply with baseline identifiers, backup paths and checksums, the Windows backup confirmation, the LUKS-header and filesystem UUIDs, the carried NetworkManager keep-list, validation results, and the soak and consolidation checkpoints. Never record secret values.
