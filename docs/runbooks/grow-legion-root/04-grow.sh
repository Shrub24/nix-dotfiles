#!/usr/bin/env bash
# Step 4 — grow the dm-crypt mapping and then the Btrfs filesystem.
#
#   sudo bash 04-grow.sh
#
# Run from the booted system, after step 3 has grown the partition. If step 3
# asked for a reboot, run this after it.
set -euo pipefail
export LC_ALL=C
umask 077
. "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
load_state
require_root
for c in blockdev cryptsetup btrfs grep; do need "$c"; done

[ "$(blockdev --getsize64 "$CRYPT_PART")" = "$EXPECTED_BYTES" ] \
  || fail "the kernel still reports the old root extent; reboot, then run this script again"

printf '== mapping ==\n'
MAPPER_BEFORE=$(blockdev --getsize64 /dev/mapper/cryptroot)
printf 'before: %s bytes\n' "$MAPPER_BEFORE"
cryptsetup resize cryptroot
cryptsetup status cryptroot
MAPPER_AFTER=$(blockdev --getsize64 /dev/mapper/cryptroot)
printf 'after:  %s bytes\n' "$MAPPER_AFTER"
[ "$MAPPER_AFTER" -gt "$MAPPER_BEFORE" ] \
  || fail "the mapping did not grow; stop and inspect it before touching the filesystem"

printf '\nThe mapping is grown. The next command grows the Btrfs filesystem on it.\n'
read -r -p 'Type GROW FILESYSTEM to continue: ' CONFIRM
[ "$CONFIRM" = 'GROW FILESYSTEM' ] || fail "stopped before the filesystem resize"

printf '\n== filesystem ==\n'
btrfs filesystem resize max /
btrfs filesystem usage -b /
df -h /

printf '\n== subvolumes ==\n'
for sv in @ @nix @cache @log @tmp @images @snapshots; do
  grep -q "path ${sv}\$" "$BACKUP/subvolumes-before.txt" || fail "$sv is missing from the pre-change list"
  grep -q "path ${sv}\$" <(btrfs subvolume list /) || fail "$sv is missing after the resize"
  printf '%s present\n' "$sv"
done

printf '\nReboot and verify unlock, the root size, /boot, home and the services. Then\n'
printf 'remove the Limine firmware entry (nixos-dual-boot-install 7.5) and record the\n'
printf 'final layout.\n'
printf '\nOK: step 4 complete.\n'
