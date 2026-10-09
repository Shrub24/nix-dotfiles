# Grow the legion root partition

Arch retirement frees the tail of the Samsung disk, and the root partition is then
grown into it. The partition was created with a fixed end because the Arch partitions
and the Windows recovery partition sat after it; `_disko.nix` already declares
`cryptroot = { size = "100%"; }`, so this procedure brings the disk in line with the
declaration rather than changing it.

This is the second half of the retirement: it deletes `nvme1n1p4`, `p5` and `p6`, and it
is only run after the soak has been ended deliberately (change
`nixos-dual-boot-install` group 7). Nothing here is reversible without the backups the
first step takes.

## Target layout

| Partition                                        | Before                    | After                         |
| ------------------------------------------------ | ------------------------- | ----------------------------- |
| p1 `disk-samsung-ESP`                            | 2 GiB, `/boot`            | unchanged                     |
| p2 `disk-samsung-cryptroot`                      | sectors 4196352–343046143 | sectors 4196352–_last usable_ |
| p4 WinRE (`b5c0d8da-…`, ntfs)                    | 881 MiB                   | deleted                       |
| p5 Arch root (`e33cb524-…`, btrfs `EndeavourOS`) | 310.5 GiB                 | deleted                       |
| p6 Arch ESP (`1a2c5601-…`, vfat)                 | 2 GiB                     | deleted                       |

The disk is `/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00BL2_S6Z5NE0W500203` (Samsung
MZVL2512HDJD-00BL2, serial `S6Z5NE0W500203`). The initrd opens the container through
`/dev/disk/by-partlabel/disk-samsung-cryptroot`, so the partition's label, PARTUUID and
start sector must survive; only its end moves.

## Preconditions

- Group 7.1 is decided and the post-soak error check is recorded.
- A LUKS header backup exists off-machine and is current. A header restored from before
  TPM enrolment loses the TPM keyslot — the passphrase still opens the container, and
  `systemd-cryptenroll` re-adds the token afterwards.
- NixOS install media is at hand and a known-good generation is bootable.
- Nothing from p4, p5 or p6 is mounted.

## Step 1 — assert and back up

Run as root. The assertions are read-only; the step only writes backups.

```sh
DISK=/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00BL2_S6Z5NE0W500203
CRYPT_PART=$DISK-part2
BACKUP=/root/arch-retirement

fail() { printf 'REFUSING: %s\n' "$1" >&2; exit 1; }

[ "$(lsblk -dno SERIAL "$DISK")" = S6Z5NE0W500203 ] || fail "not the Samsung disk"
read -r START END <<<"$(partx -o START,END -n 2 "$DISK")"
[ "$START" = 4196352 ] || fail "cryptroot starts at $START, not 4196352"
[ "$(lsblk -no PARTUUID "$CRYPT_PART")" = 5e3c5ade-3810-4499-83be-d47a53dc0a10 ] \
  || fail "cryptroot PARTUUID changed"
[ "$(lsblk -no UUID "$CRYPT_PART")" = 4cdc2701-dfa3-4bee-87b6-ea85b0e772c3 ] \
  || fail "LUKS UUID changed"
[ "$(lsblk -no PARTUUID "$DISK-part4")" = b5c0d8da-da4f-49d9-a03b-be4f23908dd1 ] \
  || fail "p4 is not WinRE"
[ "$(lsblk -no PARTUUID "$DISK-part5")" = e33cb524-3620-49ce-a895-01ca6117ef19 ] \
  || fail "p5 is not the Arch root"
[ "$(lsblk -no PARTUUID "$DISK-part6")" = 1a2c5601-1793-4364-bee7-c5df7c0cc8f3 ] \
  || fail "p6 is not the Arch ESP"
for n in 4 5 6; do
  findmnt -rn -S "$DISK-part$n" >/dev/null && fail "p$n is mounted"
done
[ -f "$BACKUP/nixos-luks-header.img" ] || fail "no LUKS header backup"
[ "$(stat -c %a "$BACKUP/nixos-luks-header.img")" = 600 ] || fail "header backup is not 0600"

LAST=$(sgdisk --print "$DISK" | sed -n 's/^Last usable sector is \([0-9]*\)$/\1/p')
[ -n "$LAST" ] || fail "cannot read the GPT last usable sector"

mkdir -p "$BACKUP"
sgdisk --backup="$BACKUP/gpt-nvme1n1-$(date +%F).bin" "$DISK"

printf 'cryptroot: %s-%s -> %s-%s (+%s GiB)\n' \
  "$START" "$END" "$START" "$LAST" "$(( (LAST - END) / 2097152 ))"
```

Stop if the growth figure is not the tail of the disk, and copy both backups
off-machine before continuing.

## Step 2 — apply

```sh
sudo sgdisk --delete=4 --delete=5 --delete=6 "$DISK"
sudo sgdisk --resize=2:4196352:"$LAST" "$DISK"
sudo sgdisk --verify "$DISK"
sudo sgdisk --print "$DISK"
sudo partx -u "$DISK"
```

Then grow the container and the filesystem it holds, from the running system:

```sh
sudo cryptsetup resize cryptroot
sudo btrfs filesystem resize max /
```

## Step 3 — verify

```sh
lsblk /dev/nvme1n1
sudo cryptsetup status cryptroot
sudo btrfs filesystem usage /
sudo btrfs subvolume list / | wc -l   # seven
df -h /
```

All seven subvolumes (`@`, `@nix`, `@cache`, `@log`, `@tmp`, `@images`, `@snapshots`)
must still be listed, and the mapper and the filesystem must report the partition's new
size. Reboot once and confirm the container opens and the root mounts.

## Recovery

- **Wrong table.** `sudo sgdisk --load-backup="$BACKUP/gpt-nvme1n1-<date>.bin" "$DISK"`
  then `sudo partx -u "$DISK"` restores the pre-change table; the deletions are metadata
  and the deleted filesystems are untouched until something writes over them.
- **Container will not open.** Test the header backup against a copy of the partition
  before restoring it: `sudo cryptsetup luksHeaderRestore` is a write to the container's
  header and the backup may predate TPM enrolment.
- **System will not boot.** Boot the install media, `cryptsetup open
/dev/disk/by-partlabel/disk-samsung-cryptroot cryptroot`, mount the subvolumes, and
  reinstall or re-apply from the recorded revision. The configuration is reproducible
  from this repository; the header backup is what restores access if the header is the
  problem.
- **Filesystem resize fails after the mapper grew.** Nothing is lost: the partition and
  the mapper are already grown, so re-run `sudo btrfs filesystem resize max /`, after a
  reboot if necessary.

## What not to do

- Do not end the partition at the disk's final sector. The secondary GPT header lives
  there; use the GPT last usable sector `sgdisk` reports.
- Do not delete and recreate the LUKS partition. A new PARTUUID or label breaks the
  initrd's `by-partlabel` reference and the disko declaration.
- Do not create or format anything, and do not re-run disko against this disk outside a
  fresh install.
- Do not resize the filesystem before the mapper.
