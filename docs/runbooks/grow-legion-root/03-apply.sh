#!/usr/bin/env bash
# Step 3 — write the verified replacement GPT to the disk.
#
#   sudo bash 03-apply.sh
#
# Destructive: WinRE and the Arch partitions are retired here.
set -euo pipefail
export LC_ALL=C
umask 077
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
load_state
require_root
for c in lsblk sgdisk partx blockdev sync; do need "$c"; done

[ -f "$BACKUP/gpt-grown.bin" ] && [ -f "$BACKUP/candidate.img" ] \
  || fail "no verified candidate in $BACKUP; run 02-stage.sh first"
[ "$(cat "$BACKUP/table-before.txt")" = "$(sgdisk --print "$DISK")" ] \
  || fail "the GPT changed since preflight; run 01-preflight.sh again"
for n in 4 5 6; do
  [ -z "$(lsblk -n -o MOUNTPOINTS "${DISK}-part$n")" ] || fail "p$n or a child is mounted"
  [ -z "$(lsblk -n -o HOLDERS "${DISK}-part$n")" ] || fail "p$n has holders"
done

printf 'This deletes p4 (WinRE), p5 (Arch root) and p6 (Arch ESP), and grows p2 to sector %s.\n' "$LAST"
printf 'Arch becomes unbootable and its data unrecoverable.\n'
printf 'The GPT and LUKS-header backups must already be verified off-machine.\n\n'
read -r -p 'Type DELETE ARCH to continue: ' CONFIRM
[ "$CONFIRM" = 'DELETE ARCH' ] || fail "not approved"

sgdisk --load-backup="$BACKUP/gpt-grown.bin" "$DISK"
[ "$(cat "$BACKUP/esp-before.txt")" = "$(sgdisk --info=1 "$DISK")" ] \
  || fail "the ESP entry differs after the write"
[ "$(sgdisk --info=2 "$DISK")" = "$(sgdisk --info=2 "$BACKUP/candidate.img")" ] \
  || fail "the root entry differs after the write"
sgdisk --verify "$DISK"
printf '\n== disk table ==\n'
sgdisk --print "$DISK"
sync

if ! partx --delete --nr 4:6 "$DISK"; then
  printf 'note: kernel entries 4-6 were already absent\n'
fi
partx --update --nr 2 "$DISK" \
  || fail "the GPT is written but the kernel refused the new root extent. Do not rewrite the GPT: reboot, then run 04-grow.sh."

KERNEL_BYTES=$(blockdev --getsize64 "$CRYPT_PART")
printf '\nkernel root partition: %s bytes (expected %s)\n' "$KERNEL_BYTES" "$EXPECTED_BYTES"
[ "$KERNEL_BYTES" = "$EXPECTED_BYTES" ] \
  || fail "the kernel still reports the old extent. Do not rewrite the GPT: reboot, then run 04-grow.sh."

printf '\nOK: step 3 complete. Next: 04-grow.sh (container and filesystem).\n'
