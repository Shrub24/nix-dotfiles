#!/usr/bin/env bash
# Step 1 — assert the disk identity and capture the rollback artefacts.
#
#   sudo bash 01-preflight.sh [EXISTING_BACKUP_DIR]
#
# Read-only with respect to the disk. Pass an existing backup directory to reuse
# a set already verified and copied off-machine.
set -euo pipefail
export LC_ALL=C
umask 077
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

DISK=/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00BL2_S6Z5NE0W500203
CRYPT_PART=${DISK}-part2
EXPECTED_SERIAL=S6Z5NE0W500203
EXPECTED_WWN=eui.002538b531027bf1
EXPECTED_START=4196352
EXPECTED_END=343046143
EXPECTED_ESP_PARTUUID=5725c8a7-eb37-41e1-b3b3-7475c3a32e06
EXPECTED_ROOT_PARTUUID=5e3c5ade-3810-4499-83be-d47a53dc0a10
EXPECTED_LUKS_UUID=4cdc2701-dfa3-4bee-87b6-ea85b0e772c3
EXPECTED_WINRE_PARTUUID=b5c0d8da-da4f-49d9-a03b-be4f23908dd1
EXPECTED_ARCH_PARTUUID=e33cb524-3620-49ce-a895-01ca6117ef19
EXPECTED_ARCH_ESP_PARTUUID=1a2c5601-1793-4364-bee7-c5df7c0cc8f3
LUKS_MAGIC=4c554b53babe

require_root
for c in lsblk blockdev sgdisk cryptsetup btrfs sha256sum od stat truncate; do need "$c"; done

printf '== identity ==\n'
[ "$(lsblk -dn -o SERIAL "$DISK")" = "$EXPECTED_SERIAL" ] || fail "wrong disk serial"
[ "$(lsblk -dn -o WWN "$DISK")" = "$EXPECTED_WWN" ] || fail "wrong disk WWN"
[ "$(blockdev --getss "$DISK")" = 512 ] || fail "unexpected sector size"
[ "$(lsblk -dn -o PARTUUID "$CRYPT_PART")" = "$EXPECTED_ROOT_PARTUUID" ] || fail "wrong root PARTUUID"
[ "$(lsblk -dn -o PARTLABEL "$CRYPT_PART")" = disk-samsung-cryptroot ] || fail "wrong root label"
[ "$(lsblk -dn -o UUID "$CRYPT_PART")" = "$EXPECTED_LUKS_UUID" ] || fail "wrong LUKS UUID"
[ "$(lsblk -dn -o PARTUUID "${DISK}-part1")" = "$EXPECTED_ESP_PARTUUID" ] || fail "wrong NixOS ESP"
[ "$(lsblk -dn -o PARTUUID "${DISK}-part4")" = "$EXPECTED_WINRE_PARTUUID" ] || fail "wrong WinRE partition"
[ "$(lsblk -dn -o PARTUUID "${DISK}-part5")" = "$EXPECTED_ARCH_PARTUUID" ] || fail "wrong Arch root"
[ "$(lsblk -dn -o PARTUUID "${DISK}-part6")" = "$EXPECTED_ARCH_ESP_PARTUUID" ] || fail "wrong Arch ESP"
for n in 4 5 6; do
  [ -z "$(lsblk -n -o MOUNTPOINTS "${DISK}-part$n")" ] || fail "p$n or a child is mounted"
  [ -z "$(lsblk -n -o HOLDERS "${DISK}-part$n")" ] || fail "p$n has holders"
done

TABLE=$(sgdisk --print "$DISK")
P1=$(sgdisk --info=1 "$DISK")
P2=$(sgdisk --info=2 "$DISK")
START=$(printf '%s\n' "$P2" | sed -n 's/^First sector: \([0-9][0-9]*\).*/\1/p')
END=$(printf '%s\n' "$P2" | sed -n 's/^Last sector: \([0-9][0-9]*\).*/\1/p')
LAST=$(printf '%s\n' "$TABLE" | sed -n 's/.*, last usable sector is \([0-9][0-9]*\).*/\1/p')
TYPE=$(printf '%s\n' "$P2" | sed -n 's/^Partition GUID code: \([^ ]*\).*/\1/p')
FLAGS=$(printf '%s\n' "$P2" | sed -n 's/^Attribute flags: \([[:xdigit:]]*\).*/\1/p')
GUID=$(printf '%s\n' "$TABLE" | sed -n 's/^Disk identifier (GUID): //p')
ROWS=$(printf '%s\n' "$TABLE" | sed -n 's/^ *\([0-9][0-9]*\)  .*/\1/p' | tr '\n' ' ')
[ "$ROWS" = '1 2 4 5 6 ' ] || fail "unexpected partition set: $ROWS"
[ "$START" = "$EXPECTED_START" ] || fail "unexpected root start"
[ "$END" = "$EXPECTED_END" ] || fail "unexpected root end — rerunning after growth is not supported"
[ -n "$LAST" ] && [ "$LAST" -gt "$END" ] || fail "no room to grow"
[ -n "$TYPE" ] && [ -n "$GUID" ] && [ "${#FLAGS}" = 16 ] || fail "incomplete GPT metadata"
EXPECTED_BYTES=$(( (LAST - START + 1) * 512 ))
sgdisk --verify "$DISK"

BACKUP=${1:-$STATE_DIR/backup-$(date -u +%Y%m%d-%H%M%S)}
mkdir -p "$BACKUP"
chmod 700 "$BACKUP"
printf '%s\n' "$TABLE" >"$BACKUP/table-before.txt.new"
[ ! -f "$BACKUP/table-before.txt" ] \
  || diff -q "$BACKUP/table-before.txt.new" "$BACKUP/table-before.txt" >/dev/null \
  || fail "the live table no longer matches the recorded one in $BACKUP"
mv "$BACKUP/table-before.txt.new" "$BACKUP/table-before.txt"

if [ -f "$BACKUP/gpt-before.bin" ] && [ -f "$BACKUP/nixos-luks-header.img" ]; then
  printf '== reusing the backups in %s ==\n' "$BACKUP"
else
  printf '== taking backups ==\n'
  sgdisk --backup="$BACKUP/gpt-before.bin" "$DISK"
  cryptsetup luksHeaderBackup "$CRYPT_PART" --header-backup-file "$BACKUP/nixos-luks-header.img"
fi
chmod 600 "$BACKUP/gpt-before.bin" "$BACKUP/nixos-luks-header.img"

printf '%s\n' "$P1" >"$BACKUP/esp-before.txt"
printf '%s\n' "$P2" >"$BACKUP/root-before.txt"
cryptsetup status cryptroot >"$BACKUP/mapper-before.txt"
cryptsetup luksDump "$CRYPT_PART" >"$BACKUP/luks-dump.txt"
btrfs filesystem usage -b / >"$BACKUP/btrfs-before.txt"
btrfs subvolume list / >"$BACKUP/subvolumes-before.txt"

printf '\n== backup verification ==\n'
(
  cd "$BACKUP"
  sha256sum gpt-before.bin nixos-luks-header.img >SHA256SUMS
  sha256sum -c SHA256SUMS
)
[ "$(stat -c %a "$BACKUP/nixos-luks-header.img")" = 600 ] || fail "the header backup is not mode 0600"
[ "$(stat -c %s "$BACKUP/nixos-luks-header.img")" = 16777216 ] || fail "unexpected header backup size"
[ "$(od -An -tx1 -N6 "$BACKUP/nixos-luks-header.img" | tr -d ' \n')" = "$LUKS_MAGIC" ] \
  || fail "the header backup has no LUKS magic"

printf '\n== passphrase test ==\n'
printf 'Type the LUKS passphrase; the container is not activated.\n'
cryptsetup open --test-passphrase "$CRYPT_PART" unused-name \
  || fail "the passphrase does not unlock this container — resolve this before growing it"

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"
{
  printf 'DISK=%q\n' "$DISK"
  printf 'CRYPT_PART=%q\n' "$CRYPT_PART"
  printf 'BACKUP=%q\n' "$BACKUP"
  printf 'START=%q\n' "$START"
  printf 'END=%q\n' "$END"
  printf 'LAST=%q\n' "$LAST"
  printf 'TYPE=%q\n' "$TYPE"
  printf 'FLAGS=%q\n' "$FLAGS"
  printf 'GUID=%q\n' "$GUID"
  printf 'ROOT_PARTUUID=%q\n' "$EXPECTED_ROOT_PARTUUID"
  printf 'EXPECTED_BYTES=%q\n' "$EXPECTED_BYTES"
} >"$STATE_FILE"
chmod 600 "$STATE_FILE"

printf '\n== summary ==\n'
printf 'root:      sectors %s-%s -> %s-%s (+%s GiB)\n' \
  "$START" "$END" "$START" "$LAST" "$(( (LAST - END) / 2097152 ))"
printf 'artefacts: %s\n' "$BACKUP"
printf 'state:     %s\n' "$STATE_FILE"
printf '\nCopy gpt-before.bin, nixos-luks-header.img and SHA256SUMS off-machine and\n'
printf 'verify the checksums there. The header backup permits offline attacks on the\n'
printf 'keyslots, so keep it root-only at the destination.\n'
printf '\nOK: step 1 complete. Next: 02-stage.sh (writes only a sparse file).\n'
