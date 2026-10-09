# Tasks — Dual-Boot NixOS Install

> Standing rule: every destructive task below is approval-gated (`notes: explicit
user approval required immediately before execution`), and every disk target
> resolves by serial/WWN, PARTUUID or partlabel — never `/dev/nvmeX`. The install
> ran from the running pre-install system; execution evidence is appended to the
> Execution Record in this file, and no ad-hoc task-state file is canonical.

## Group 1 — Gate, Windows backup, baseline (delivered)

- [x] 1.1–1.5 Delivered. The bare-metal-readiness gate passed; the Windows C:
      backup was confirmed before any GPT write; the live baseline (both disk
      serials, every PARTUUID/partlabel and start/end sector, the LinuxData and
      Shared filesystem UUIDs, `uname -r`, `limine.conf`, `efibootmgr`) was
      captured; both GPTs and all three ESPs were backed up cross-disk with
      sha256 checksums; and UEFI mode with writable efivars was asserted before
      the first destructive step.

  - evidence: the installed system is the gate artifact; backups live in
    `/data/install-backups/` and `/root/install-backups/` (`docs/runbooks/provision-legion.md` §§2–3)
  - refs: design D1, D2, D4, D5, D12

## Group 2 — Samsung: Windows removed, root provisioned (delivered)

- [x] 2.1–2.5 Delivered. Windows p1–p3 were replaced by the 2 GiB ESP
      (`disk-samsung-ESP`) and the LUKS2 `disk-samsung-cryptroot` partition;
      Arch p5/p6 kept their identities and bounds; the target was formatted
      FAT32 + LUKS2 (passphrase only, no TPM) + btrfs; and the seven subvolumes
      `@`, `@nix`, `@cache`, `@log`, `@tmp`, `@images` and `@snapshots` were
      created with the data disk's `@home` and `@data` mounted at `/mnt/home`
      and `/mnt/data` so no shadow home was written to the LUKS container.

  - evidence: `modules/hosts/legion/_disko.nix` declares the delivered layout
  - refs: design D2, D3, D5, D6, D7, D8

## Group 3 — SK hynix: retired Fedora removal (delivered)

- [x] 3.1–3.3 Delivered. The retired Fedora ESP and ext4 were deleted with fresh
      identity assertions and nothing created in their place; Windows, Shared and
      LinuxData kept their PARTUUIDs, partlabels and bounds; and the SK hynix GPT
      and Fedora ESP backup was copied into the new root so it outlives the
      pre-install system.

  - evidence: `docs/runbooks/provision-legion.md` §4; `/home` and `/data` still
    resolve to LinuxData
  - refs: design D9, D12

## Group 4 — Root state carry, then the export checkout (delivered)

- [x] 4.1–4.4 Delivered. `/etc/ssh/ssh_host_*`, `/var/lib/sops-nix/key.txt`,
      `/var/lib/tailscale` and `/var/lib/bluetooth` were copied into the target
      with ownership and mode preserved; exactly the operator's keep-list of
      NetworkManager profiles was copied; the excluded service state (ollama,
      docker, flatpak) was left behind and no secret material reached an
      artifact; and the install ran from a clean checkout at the recorded gate
      revision.

  - evidence: `docs/runbooks/provision-legion.md` §7; the booted system decrypts
    root secrets with the carried age key
  - refs: design D5, D11

## Group 5 — Install from the running system (delivered)

- [x] 5.1–5.3 Delivered. `nixos-install` ran from the running system into the
      mounted target, installing the gate-built toplevel; the primary user's
      password was set before first boot and never recorded; and the Windows and
      Fedora firmware entries were removed while Limine stayed.

  - evidence: the installed system boots through the new NixOS entry;
    `docs/runbooks/provision-legion.md` §8
  - refs: design D5, D10

- [x] 5.4 Not exercised. The NixOS-media fallback is a contingency; the
      running-system path succeeded, so no media boot occurred.

## Group 6 — Boot verification and soak (delivered)

- [x] 6.1–6.3 Delivered. The new entry boots with LUKS decryption, all declared
      mounts, `/home` and `/data` on LinuxData, network, Home Manager, desktop,
      secrets, tailnet identity, Syncthing and the NVIDIA/iGPU stack; Arch still
      boots through Limine as the rollback path and the freed SK hynix extent is
      still free; and the carried root state was verified from the booted system,
      not from the mount.

  - evidence: the installed system is the current daily driver
  - refs: design D7, D8, D11

- [x] 6.4 Soak checkpoint recorded in the Execution Record below. The post-soak
      group has not run.

  - refs: design D13

## Group 7 — Post-soak consolidation (delivered)

- [x] 7.1–7.5 Delivered. The operator ended the soak deliberately and approved the
      consolidation on 2026-10-10. `01-preflight.sh` and `02-stage.sh` ran read-only
      with respect to the disk; `03-apply.sh` made the single GPT write, retiring
      p4/p5/p6 and growing `disk-samsung-cryptroot` from sector 4196352 to the GPT
      last usable sector; `04-grow.sh` grew the container and then the filesystem.
      The `Limine` entry and a duplicate `EFI Hard Drive 1` entry — both addressing
      the Arch ESP — were removed, leaving the NixOS entry as the only one for this
      disk.

  - criteria met: the ESP and the root's start, PARTUUID, type, label and attributes
    are unchanged; the new end is the last usable sector; the mapper and the btrfs
    both match the partition; all seven subvolumes intact
  - evidence: the Execution Record below; `docs/runbooks/grow-legion-root.md`
  - refs: design D12, D13
  - note: 7.5 ran before the reboot rather than after it, because 7.3 had already
    deleted the ESP both entries pointed at — a systemd-boot failure could otherwise
    have fallen through into dead entries.

## Group 8 — Handoff and deferred scope (3)

- [ ] 8.1 Update operator documentation with the actual UUIDs, partlabels, backup
      paths, the install path that ran, and the verification results.

  - depends: 7.5
  - reason: still open — `docs/runbooks/provision-legion.md` still states that its
    commands have not been executed, and the actual identifiers are unrecorded.

- [ ] 8.2 Run strict OpenSpec validation and repository checks; all green.

  - verify: `openspec validate --all --strict` and `nix flake check --no-build --no-write-lock-file`
  - depends: 8.1
  - reason: still open — blocked on 8.1; strict OpenSpec validation itself is green.

- [ ] 8.3 Record deferred scope explicitly: the eventual Windows reinstall into the
      freed SK hynix extent and LinuxData's trailing ~27.3 GiB. No task in this
      change partitions, mounts or writes into that freed extent. TPM enrolment for
      the LUKS root is done (2026-10-09: PCR 7 token added, passphrase retained as
      fallback), so it is no longer deferred scope.

  - criteria: the deferred items are stated where the follow-up work will look for them
  - verify: docs state them; no task above touches the freed extent
  - depends: 8.2
  - reason: still open — the deferred items are stated in the design but not in
    the operator documentation.

## Execution Record

Recorded after first boot. Values not written here were not captured, and are
not guessed.

### Gate and install

- Install path: `nixos-install` from the running pre-install system into the
  mounted target, installing the gate-built toplevel. The NixOS-media fallback
  was not used.
- Installed layout: 2 GiB ESP (`disk-samsung-ESP`) plus the LUKS2
  `disk-samsung-cryptroot` partition holding btrfs with `@`, `@nix`, `@cache`,
  `@log`, `@tmp`, `@images` and `@snapshots`; `@home` and `@data` remain on the
  SK hynix LinuxData filesystem (`47fa5ee2-…`). No `@persist` was created.
- Boot: verified through the new NixOS firmware entry, with Limine retained for
  the pre-install system.
- Backups: both GPTs and all three ESPs were written to
  `/data/install-backups/` and `/root/install-backups/`
  (`docs/runbooks/provision-legion.md` §3).

### Soak checkpoint

- Verified state: NixOS is the daily system; the pre-install system still boots
  through Limine; the freed SK hynix extent is still unpartitioned.
- Rollback: selecting Limine returns to the pre-install system. No post-soak work
  has run, so nothing outside the new root has been destroyed.

### Post-soak error check (2026-10-09)

- Failed units: none, on the boot that follows generation `system-16` (built 16:36,
  rebooted 20:43).
- Error-priority journal: 135 lines and no faults among them — 73 kernel ACPI firmware
  complaints (Lenovo `_UPC`/`_PLD` `AE_ALREADY_EXISTS`), 25 dbus-broker-launch
  duplicate-name notices for packages also reachable through `system-path`, 14 Grist lines
  (it logs its own info to stderr), 4 JSON-schema strict-mode warnings, 2 Bluetooth SDP
  "Host is down", 1 greetd. The previous boot held 1,299 lines across roughly two days.
- Boot timing: firmware 5.8 s, loader 1.6 s, kernel 1.7 s, initrd 2.8 s, userspace 14.5 s.
  The initrd figure is the evidence that no passphrase was typed: TPM unlock is in effect.
- Timezone: `Australia/Melbourne` (AEDT), NTP synced, geoclue active, on a boot whose
  Wi-Fi came up (`wlp0s20f3`, `iwlmvm` loaded) — the iwlwifi-out-of-initrd change holds.
- Greeter: `pkexec … noctalia-greeter-apply-appearance --sync` ran at 20:43:45 with no
  prompt, and the passwordless rule is live in `/etc/polkit-1/rules.d/10-nixos.rules`.
- Portal: the 26 s startup deadlock between the frontend and the KDE backend is
  root-caused and changed in `modules/desktop/portals.nix`; the next switch verifies it.
- `/boot` is mode 0700 root, so the ESP's loader configuration (menu timeout, console
  mode, Plymouth theme) cannot be read as the login user; ESP use is 139 MiB of 2 GiB.
- Not yet confirmed by eye: the boot menu and splash, and the phone widget listing the
  paired phone.

### Not captured (do not guess)

- The Windows C: backup's location and date, and the baseline capture checksums.
- The NetworkManager keep-list filenames.

### Post-soak consolidation (2026-10-10)

- Backups: GPT and LUKS header written to `/root/arch-retirement-20261009-143304/`,
  checksums verified, then copied off-machine to `home-forge:/root/luks-backups/legion`
  (directory 0700, files 0600), where both checksums verify. The first copy landed
  world-readable in `/home/dev` and was corrected.
- Applied: p4/p5/p6 deleted; `disk-samsung-cryptroot` grew from 173,491,093,504 to
  509,961,641,472 bytes — sector 4196352 to the GPT last usable sector, +313 GiB —
  with its start, PARTUUID, type, label and attributes unchanged and the ESP
  untouched.
- Container: `cryptsetup resize cryptroot` → 509,944,864,256 bytes, the partition less
  the 16 MiB data offset. Root filesystem: 162 G → 475 G, 36 G used, 433 G free.
- Reboot verification: TPM unlock in 1 s (`systemd-cryptsetup@cryptroot` starting
  03:58:52, finished 03:58:53), initrd 2.93 s, all seven subvolumes mounted (`@`,
  `@nix`, `@cache`, `@log`, `@tmp`, `@images`, `@snapshots`), `/home`, `/data` and
  `/mnt/Shared` present, no failed units, and 135 error-priority journal lines — the
  same benign set as the pre-consolidation boot, so the operation added none.
- `btrfs device stats`: read, write, flush, corruption and generation errors all zero.
- Firmware: `BootOrder: 0005,0000,2001,2002,2003`, with only the systemd-boot entry
  for this disk.
- NVMe enumeration is not stable across boots: the Samsung was `nvme1n1` before the
  reboot and `nvme0n1` after it, the SK hynix swapping the other way. Nothing depends
  on it — the configuration addresses disks by by-id, partlabel and PARTUUID.
- No secondary-header work was needed. LUKS2 keeps both metadata copies inside the
  first 16 MiB header area (offsets 4096 and 20480), so growing the partition cannot
  disturb them; the end-of-device backup header is LUKS1 behaviour, and the growth
  created none.

### Identifiers

- LUKS2 container: UUID `4cdc2701-dfa3-4bee-87b6-ea85b0e772c3`, no header label
  (`luksDump` reports `(no label)`; the `nixos-root` label lsblk shows on the mapper
  is the btrfs filesystem's).
- Root filesystem: btrfs UUID `1ca6a2d8-4597-44f8-bfa9-764df4c66044`, label `nixos-root`.
- ESP: vfat UUID `21F0-3462`, PARTUUID `5725c8a7-eb37-41e1-b3b3-7475c3a32e06`.
- Root partition: PARTUUID `5e3c5ade-3810-4499-83be-d47a53dc0a10`, partlabel
  `disk-samsung-cryptroot`.
- LinuxData: btrfs UUID `47fa5ee2-addd-466b-b7fc-4e7d92968234`; Shared NTFS:
  `2EBA15A2BA15681B`.

### Remaining

- Group 8 only. The consolidation above is complete; nothing else in this change
  touches the disk.

Never record secret values.
