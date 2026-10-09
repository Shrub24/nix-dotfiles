#!/usr/bin/env bash
# Step 2 — build and verify the replacement GPT in a sparse file.
#
#   sudo bash 02-stage.sh
#
# Writes only $BACKUP/candidate.img. The disk is not touched.
set -euo pipefail
export LC_ALL=C
umask 077
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
load_state
require_root
for c in truncate sgdisk blockdev; do need "$c"; done

CANDIDATE=$BACKUP/candidate.img
[ -f "$BACKUP/gpt-before.bin" ] || fail "no GPT backup in $BACKUP; run 01-preflight.sh first"
[ -f "$BACKUP/esp-before.txt" ] && [ -f "$BACKUP/root-before.txt" ] \
  || fail "no recorded partition entries in $BACKUP; run 01-preflight.sh first"

strip_size() { sed '/^Last sector:/d; /^Partition size:/d'; }

rm -f "$CANDIDATE"
truncate -s "$(blockdev --getsize64 "$DISK")" "$CANDIDATE"
sgdisk --load-backup="$BACKUP/gpt-before.bin" "$CANDIDATE"
sgdisk --delete=4 --delete=5 --delete=6 --delete=2 "$CANDIDATE"
sgdisk --new=2:"$START":"$LAST" "$CANDIDATE"
sgdisk --typecode=2:"$TYPE" \
  --change-name=2:disk-samsung-cryptroot \
  --partition-guid=2:"$ROOT_PARTUUID" \
  --attributes=2:=:"$FLAGS" "$CANDIDATE"

printf '== the candidate keeps ==\n'
[ "$(cat "$BACKUP/esp-before.txt")" = "$(sgdisk --info=1 "$CANDIDATE")" ] \
  || fail "the ESP entry changed"
[ "$GUID" = "$(sgdisk --print "$CANDIDATE" | sed -n 's/^Disk identifier (GUID): //p')" ] \
  || fail "the disk GUID changed"
[ "$(strip_size <"$BACKUP/root-before.txt")" = "$(sgdisk --info=2 "$CANDIDATE" | strip_size)" ] \
  || fail "the root entry changed beyond its size"
[ "$(sgdisk --info=2 "$CANDIDATE" | sed -n 's/^Last sector: \([0-9][0-9]*\).*/\1/p')" = "$LAST" ] \
  || fail "the root does not end at the last usable sector"
ROWS=$(sgdisk --print "$CANDIDATE" | sed -n 's/^ *\([0-9][0-9]*\)  .*/\1/p' | tr '\n' ' ')
[ "$ROWS" = '1 2 ' ] || fail "unexpected replacement partition set: $ROWS"
printf 'the ESP, the disk GUID and the root start/PARTUUID/type/label/attributes\n'

sgdisk --verify "$CANDIDATE"
printf '\n== candidate ==\n'
sgdisk --print "$CANDIDATE"
sgdisk --backup="$BACKUP/gpt-grown.bin" "$CANDIDATE"

printf '\nThe candidate removes p4/p5/p6 and ends the root at sector %s. The unaligned-end\n' "$LAST"
printf 'caution from sgdisk --verify is expected: the last usable sector is not 2048-aligned.\n'
printf '\nOK: step 2 complete. Next: 03-apply.sh (destructive — writes the disk).\n'
