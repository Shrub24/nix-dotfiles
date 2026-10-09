# Grow the legion root partition

Arch retirement frees the tail of the Samsung disk. Its root partition can then
grow into that space; `_disko.nix` already declares `cryptroot.size = "100%"`.
This does not depend on the tentative root-preservation plan.

The procedure is four scripts beside this file. Run each with `sudo bash`, from
a normal shell — including fish. They are scripts rather than pasted blocks
because each sets `set -euo pipefail`: pasted into an interactive shell, one
failing command (or a merged paste) exits that shell and loses its variables.

This deletes WinRE, the Arch root and the Arch ESP. It requires the explicit
end-of-soak decision in `nixos-dual-boot-install` group 7 and approval
immediately before the real GPT write. It was executed on 2026-10-10; see
[Outcome](#outcome-2026-10-10).

## Target layout

| Partition                   | Before                                          | After                           |
| --------------------------- | ----------------------------------------------- | ------------------------------- |
| p1 `disk-samsung-ESP`       | 2 GiB, `/boot`                                  | unchanged                       |
| p2 `disk-samsung-cryptroot` | sectors 4196352–343046143                       | same start, GPT last usable end |
| p4 WinRE                    | PARTUUID `b5c0d8da-da4f-49d9-a03b-be4f23908dd1` | deleted                         |
| p5 Arch root                | PARTUUID `e33cb524-3620-49ce-a895-01ca6117ef19` | deleted                         |
| p6 Arch ESP                 | PARTUUID `1a2c5601-1793-4364-bee7-c5df7c0cc8f3` | deleted                         |

The target is the Samsung MZVL2512HDJD-00BL2, serial `S6Z5NE0W500203`, WWN
`eui.002538b531027bf1`. Linux device numbering is not an identity: the scripts
use the stable by-id path. Home and data are on the other disk and are not
changed. The expected gain is about 313 GiB, taking the container from about
162 GiB to about 475 GiB.

The partition's start, PARTUUID, type, label and attributes must survive, and
the LUKS header and payload are never reformatted. `sgdisk` has **no `--resize`
command** in the installed gptfdisk 1.0.10; unknown options can silently do
nothing. So step 2 prepares the replacement GPT in a sparse file, verifies it,
and step 3 loads the finished table onto the disk once. Recreating the GPT entry
in that file is not recreating or formatting the LUKS container.

## Preconditions

- Accept that Arch and the old WinRE partition are being retired permanently.
  Save any Arch-only data first. A GPT backup is not a data backup.
- Have bootable NixOS rescue media and the recovery instructions in
  [provision-legion.md](provision-legion.md#recovery-media) available
  off-machine, not only on this root.
- Nothing from p4, p5 or p6 may be mounted or used by another process or device.
- Root and Btrfs must be healthy. Stop on current I/O or filesystem errors; do
  not combine repair attempts with partition growth.
- Remain on AC power. Do not run updates, switches or other disk-management
  tools while changing the table.

Growth does not require TPM re-enrolment: it leaves the LUKS header, keyslots and
tokens unchanged. The passphrase stays the recovery path, so step 1 tests it
before anything changes. Restoring an older header can discard a later TPM
enrolment and invalidate passphrases added after that backup; do not restore a
header casually.

## Step 1 — identity and rollback artefacts

```sh
sudo bash docs/runbooks/grow-legion-root/01-preflight.sh [EXISTING_BACKUP_DIR]
```

Read-only with respect to the disk. Asserts the serial, WWN, sector size, the
five PARTUUIDs and the LUKS UUID, that p4/p5/p6 are unmounted and unheld, and
the recorded root start and end; then captures the GPT backup, the LUKS header
backup, the partition entries, `luksDump`, and the Btrfs usage and subvolume
list, writes the step's state to `/root/grow-legion-root/state.env`, and verifies
the backups (checksums, `0600`, size, LUKS magic) before testing the passphrase.

Pass an existing backup directory to reuse a set already copied off-machine; it
must still match the live table. Rerunning it after growth is refused, by design.

**Gate:** copy `gpt-before.bin`, `nixos-luks-header.img` and `SHA256SUMS`
off-machine and verify the checksums there. `/root` and `/data` are not
off-machine copies. The header backup permits offline attacks on the keyslots,
so keep it root-only at the destination.

## Step 2 — stage and verify the replacement table

```sh
sudo bash docs/runbooks/grow-legion-root/02-stage.sh
```

Writes only `$BACKUP/candidate.img`, a sparse file of the disk's apparent size
holding GPT metadata. It loads the recorded table, deletes p4/p5/p6 and the root
entry, recreates the root at the recorded start and the last usable sector, and
restores its type, label, PARTUUID and attributes. Then it asserts the ESP block,
the disk GUID, and the root entry apart from its size are unchanged, that only
p1 and p2 remain, and that the root ends at the last usable sector.

The `Caution: Partition 2 doesn't end on a 2048-sector boundary` line from
`sgdisk --verify` is expected — the last usable sector is not aligned, and
rounding it up would collide with the backup GPT.

Review the printed candidate before continuing.

## Step 3 — write the table (destructive)

```sh
sudo bash docs/runbooks/grow-legion-root/03-apply.sh
```

Refuses if the live table no longer matches the preflight capture, if p4/p5/p6
became mounted or held, or if the approval phrase is not typed. It then loads the
verified table, re-asserts the ESP and root entries, removes the stale kernel
partition entries for p4–p6, updates p2, and compares the kernel's root-partition
size with the expected extent.

**If it reports that the kernel refused the new extent, stop.** The GPT is
already written: do not rewrite it. Reboot — the kernel re-reads the table at
boot — then continue with step 4.

## Step 4 — container and filesystem

```sh
sudo bash docs/runbooks/grow-legion-root/04-grow.sh
```

Requires the kernel to already report the grown partition. Runs
`cryptsetup resize cryptroot` and prints the mapping size before and after; the
mapping is smaller than the partition because of the LUKS data offset, and
alignment can leave a small unused tail. **It then stops and asks for
`GROW FILESYSTEM`** before running `btrfs filesystem resize max /` — do not
resize Btrfs if the mapping did not grow.

Finally it verifies that `@`, `@nix`, `@cache`, `@log`, `@tmp`, `@images` and
`@snapshots` were present before and after. It does not count subvolumes:
Snapper snapshots add more.

Then reboot and verify unlock, the root size, `/boot`, home and the services.
Only then remove the Limine firmware entry (`nixos-dual-boot-install` 7.5).

## Recovery boundaries

- **Before the step 3 write:** the disk is unchanged. Delete `candidate.img` or
  stop; no table restore is needed.
- **After the step 3 write, before the mapper or filesystem grew:** if the table
  is wrong, stop and recover from rescue media. The old GPT is a rollback only
  while the old extents still describe the data on disk. A reboot can itself
  enlarge the mapper, so do not assume the old table is still safe merely
  because step 4 was not typed.
- **After the mapper or filesystem grew:** do not load `gpt-before.bin`; its
  smaller partition can truncate the filesystem. Preserve the enlarged extent
  and diagnose the error. Arch is not recoverable once the root writes into its
  former sectors.
- **LUKS will not open:** check the partition start, label and UUID, and try the
  known passphrase. Do not format, re-enrol, or restore a header as a first
  response. A header restore is a separate destructive operation that requires
  matching identity and an understood backup.
- **Btrfs resize fails:** stop and inspect the exact error and the kernel and
  Btrfs health. A larger mapping does not force an immediate filesystem resize.
  Do not shrink the partition, restore the old GPT, or run `btrfs check --repair`
  reflexively.

## What not to do

- Do not use `sgdisk --resize`, `--resize-table`, `mkfs`, `luksFormat` or disko.
- Do not change the start, GUID, type, label or attributes of the root entry.
- Do not target the other disk or delete the NixOS ESP.
- Do not end at the disk's final sector; leave the secondary GPT intact.
- Do not resize Btrfs before the kernel partition and dm-crypt mapping are ready.
- Do not treat a current GPT or header backup as a backup of root or Arch data.

## Validation evidence

Reviewed 2026-10-09 against gptfdisk 1.0.10 and cryptsetup 2.8.8. All four
scripts pass `bash -n` and `shellcheck`. Steps 2 and 3 were rehearsed end to end
against a sparse file carrying the real geometry (1,000,215,216 sectors, the
recorded partition set and the real root start), with shims for the privileged
kernel-side commands: the candidate preserved the disk GUID, the ESP entry and
the root start/PARTUUID/type/label/attributes while removing p4/p5/p6 and ending
the root at the last usable sector; step 3 refused without the approval phrase,
then applied and refused to run a second time. The live identities and the
unmounted retired partitions were verified read-only against the recorded
baseline. Steps 1 and 4 were not executed during that review: they require root,
the real block device and an interactive passphrase. The rehearsal proves the
GPT arithmetic and the control flow, not the privileged kernel-side operations.

## Outcome (2026-10-10)

Executed and verified. p4/p5/p6 were deleted and `disk-samsung-cryptroot` grew
from 173,491,093,504 to 509,961,641,472 bytes — sector 4196352 to the GPT last
usable sector, +313 GiB — with its start, PARTUUID, type, label and attributes
unchanged and the ESP untouched. `cryptsetup resize` took the mapping to
509,944,864,256 bytes, the partition less the 16 MiB data offset, and the root
filesystem went from 162 G to 475 G, 36 G used, 433 G free.

The reboot after the growth unlocked through the TPM in one second, mounted all
seven subvolumes with `/home`, `/data` and `/mnt/Shared`, reported no failed
units, and added no error-priority journal lines; `btrfs device stats` counters
are zero. Both dead firmware entries — `Limine` and a duplicate `EFI Hard Drive
1` — were removed, leaving `BootOrder: 0005,0000,2001,2002,2003`. They were
removed before the reboot rather than after it, because step 3 had already
deleted the ESP they pointed at.

No secondary-header work was needed. LUKS2 keeps both metadata copies inside the
first 16 MiB header area, so growing the partition cannot disturb them; the
end-of-device backup header is LUKS1 behaviour.

The GPT and header backups are at `/root/arch-retirement-20261009-143304/` and,
off-machine, at `home-forge:/root/luks-backups/legion` (0700, files 0600,
checksums verified).
