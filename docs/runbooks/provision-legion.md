# Provision legion from Arch

Install NixOS from the running Arch system. Keep NixOS installation media available
for recovery. Run each section separately and inspect its checkpoint before
continuing. These commands have not been executed on the machine.

## Scope

- Samsung 512 GB, serial `S6Z5NE0W500203`: replace Windows partitions 1–3 with a
  2 GiB ESP and approximately 161.6 GiB of LUKS-encrypted btrfs.
- Preserve Arch root (partition 5), Arch ESP (partition 6), and WinRE (partition 4).
- Leave the SK hynix 2 TB disk, serial `ADC5N475011305I3I`, otherwise untouched:
  only its retired Fedora partitions are removed, and its LinuxData filesystem
  already holds `/home` and `/data`.
- Remove the retired Fedora partitions and create nothing in their place, leaving
  the extent free for the eventual Windows reinstall.
- Defer Arch retirement, LUKS expansion, and Windows reinstallation.
- NixOS installs systemd-boot on the new ESP. Limine is Arch's loader: it stays
  the way back into Arch through the soak and retires with Arch, not before.

**Never run `disko --mode disko` on legion.** The declaration describes the eventual
whole-disk layout; running its partitioner would destroy the Arch fallback.

The planning checklist is
[the dual-boot change](../../openspec/changes/nixos-dual-boot-install/tasks.md).
This runbook stops at the first-boot soak; Arch retirement, LUKS growth and the
Windows reinstall are not installation prerequisites. No disk operation below should be executed by an agent without fresh
operator approval.

## Pre-flight

The install consumes a commit, never the working tree. The working copy is jj's;
git's `HEAD` stays pinned to its parent revision, so an empty `git status` means
jj's working-copy commit carries nothing, and `git rev-parse HEAD` names the
revision `git archive` exports. Satisfy the gate with jj — commit the change, or
describe it and run `jj new` — never with `git add`/`git commit`, which is where a
colocated repository gets confused. All four checks run in the repository root:

```sh
git status --porcelain      # empty
git rev-parse HEAD          # the revision the export is taken from; record it
df -h /nix                  # at least 40 GiB free on the Arch root for the build
nix flake check --no-build --no-write-lock-file
```

Section 1 exports the checked-out commit, repeats the check on the export, and builds
the full toplevel; the post-build hook pushes it to the cache. Stop here or there on
any failure.

## 1. Build before changing partitions

Use Bash for the commands below, including if your login shell is fish:

```sh
bash
set -euo pipefail
cd /home/saurabhj/.dotfiles/nix

# The checked-out commit, or an earlier validated one set in REV.
REV=$(git rev-parse "${REV:-HEAD}")
EXPORT="$HOME/legion-install-$REV"
mkdir -p "$EXPORT"
git archive "$REV" | tar -x -C "$EXPORT"
printf 'Installing commit: %s\n' "$REV"
jj log -r @- --no-graph -T 'change_id.short() ++ " " ++ commit_id ++ "\n"'   # the same revision, in jj terms
df -h /nix /data

nix flake check "path:$EXPORT" --no-build --no-write-lock-file
nix build "path:$EXPORT#nixosConfigurations.legion.config.system.build.toplevel" \
  --out-link "$HOME/result-legion"
nix build --inputs-from "path:$EXPORT" nixpkgs#nixos-install-tools \
  --out-link "$HOME/result-legion-install-tools"

SYSTEM=$(readlink -f "$HOME/result-legion")
TOOLS=$(readlink -f "$HOME/result-legion-install-tools")
printf 'System: %s\nInstaller: %s\n' "$SYSTEM" "$TOOLS"
test -x "$TOOLS/bin/nixos-install"
test -x "$TOOLS/bin/nixos-enter"
```

The daemon's post-build hook uploads each completed output to the cache, so this
build is pushed as it completes. Recovery media still has to arrange the closure
itself — see the end of this runbook.

Stop if validation or either build fails. Keep the result symlinks: they protect
these outputs from garbage collection. The export excludes uncommitted changes.
Record the revision and output paths with the installation evidence. After a
terminal restart or reboot, restore the variables before continuing; do not repeat
completed partitioning or formatting steps.

## 2. Confirm backups and identity

Back up and verify everything needed from Windows C: **before proceeding**. The
GPT and ESP images in the next section do not contain Windows user files.

Check the required Arch tools:

```sh
for cmd in sgdisk sfdisk partx cryptsetup mkfs.btrfs btrfs mkfs.fat \
           efibootmgr rsync lsblk blkid; do
  command -v "$cmd"
done

DISK=/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00BL2_S6Z5NE0W500203
test -b "$DISK"
test "$(lsblk -dn -o SERIAL "$DISK" | xargs)" = S6Z5NE0W500203
test "$(sudo blockdev --getss "$DISK")" = 512
lsblk -d -o PATH,MODEL,SERIAL,SIZE "$DISK"
sudo sgdisk --print "$DISK"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,PARTUUID "$DISK"
```

Expected Samsung layout, in 512-byte sectors:

| Partition     |     Start |        End | Action |
| ------------- | --------: | ---------: | ------ |
| 1 Windows ESP |      2048 |     206847 | Delete |
| 2 MSR         |    206848 |     239615 | Delete |
| 3 Windows C:  |    239616 |  343046143 | Delete |
| 5 Arch root   | 343046144 |  994211839 | Keep   |
| 6 Arch ESP    | 994211840 |  998406143 | Keep   |
| 4 WinRE       | 998406144 | 1000210431 | Keep   |

**Stop if the identifiers or bounds differ.** Do not adjust destructive commands
by guesswork.

```sh
test -d /sys/firmware/efi/efivars
findmnt /sys/firmware/efi/efivars
sudo efibootmgr -v
findmnt /home
findmnt /data
```

EFI variables must be mounted writable. `/home` and `/data` must use LinuxData UUID
`47fa5ee2-addd-466b-b7fc-4e7d92968234` on the SK hynix. Only the Windows partitions
must be unused; Arch's root and ESP remain mounted.

## 3. Back up both tables and the ESPs

Store these backups on `/data`, on the other physical disk, and copy them
off-machine if possible. Confirm `/data` is mounted before creating the directory.

```sh
mountpoint -q /data
BACKUP="/data/install-backups/legion-$(date +%Y%m%d-%H%M%S)"
sudo install -d -m 0700 "$BACKUP"
sudo sgdisk --backup="$BACKUP/samsung.gpt" "$DISK"
sudo sfdisk --json "$DISK" | sudo tee "$BACKUP/samsung-before.json" >/dev/null
sudo efibootmgr -v | sudo tee "$BACKUP/efibootmgr-before.txt" >/dev/null

sudo dd \
  if=/dev/disk/by-partuuid/2193a654-bdaf-4647-ae55-68432ce551ad \
  of="$BACKUP/windows-esp.img" bs=4M status=progress conv=fsync
sudo dd \
  if=/dev/disk/by-partuuid/1a2c5601-1793-4364-bee7-c5df7c0cc8f3 \
  of="$BACKUP/arch-esp.img" bs=4M status=progress conv=fsync

HYNIX=/dev/disk/by-id/nvme-SHGP31-2000GM_ADC5N475011305I3I
sudo sgdisk --backup="$BACKUP/hynix.gpt" "$HYNIX"
sudo dd \
  if=/dev/disk/by-partuuid/9aae0356-4274-46c0-8593-bbcd9769b22f \
  of="$BACKUP/fedora-esp.img" bs=4M status=progress conv=fsync

sudo bash -c '
  cd "$1"
  sha256sum samsung.gpt hynix.gpt samsung-before.json windows-esp.img arch-esp.img \
    fedora-esp.img > SHA256SUMS
  sha256sum -c SHA256SUMS
' bash "$BACKUP"

# The hynix artefacts also go cross-disk: /data is on the disk being changed,
# and /root is on the Samsung, which this runbook preserves through the soak.
sudo install -d -m 0700 /root/install-backups
sudo cp -a "$BACKUP/hynix.gpt" "$BACKUP/fedora-esp.img" /root/install-backups/
sudo cmp "$BACKUP/hynix.gpt" /root/install-backups/hynix.gpt
sudo cmp "$BACKUP/fedora-esp.img" /root/install-backups/fedora-esp.img
```

The running Arch ESP may change during a kernel update. Do not run package updates
while capturing its image or during this installation.

## 4. Remove the retired Fedora partitions

**Destructive checkpoint:** both GPT backups verified, and explicit operator
approval. These two partitions are unused — nothing on them is mounted — and
nothing is created in their place. The `Fedora` firmware entry goes with them, in
section 8, once the new NixOS entry is verified.

```sh
HYNIX=/dev/disk/by-id/nvme-SHGP31-2000GM_ADC5N475011305I3I
FEDORA_ESP=/dev/disk/by-partuuid/9aae0356-4274-46c0-8593-bbcd9769b22f
FEDORA_EXT4=/dev/disk/by-partuuid/16921d6b-a8b7-4f04-8fdf-44ebc6d36acc

test "$(lsblk -dn -o SERIAL "$HYNIX" | xargs)" = ADC5N475011305I3I
for p in "$FEDORA_ESP" "$FEDORA_EXT4"; do
  test -b "$p"
  findmnt --source "$p" && { echo "$p is mounted"; exit 1; }
done
sudo sgdisk --print "$HYNIX"
```

After confirming that checkpoint, delete the two partitions:

```sh
sudo sgdisk --delete=4 --delete=5 "$HYNIX"
sudo sgdisk --verify "$HYNIX"
sudo partx --delete --nr 4:5 "$HYNIX" || true
sudo udevadm settle
sudo sfdisk --json "$HYNIX"
```

Compare against `hynix.gpt`: Windows 500 GiB (`28a0a913-…`), Shared 150 GiB
(`ab412804-…`) and LinuxData 650 GiB (`17e798c6-…`) must keep their PARTUUIDs,
partlabels and bounds, LinuxData must still carry filesystem UUID `47fa5ee2-…`, and
the freed extent must stay unpartitioned. This disk is never written again in this
runbook.

## 5. Replace Windows partitions 1–3

**Destructive checkpoint:** verified Windows backup, verified disk identity and
bounds, and explicit operator approval. Confirm the three target partitions are
not mounted, swap devices, or held open. Leave Arch partitions 5 and 6 alone.

```sh
WIN_ESP=/dev/disk/by-partuuid/2193a654-bdaf-4647-ae55-68432ce551ad
WIN_MSR=/dev/disk/by-partuuid/031ea351-43de-43d5-be70-f3acd31e5fba
WIN_C=/dev/disk/by-partuuid/9ce9fe67-debb-43d8-9dc5-2017ef5b2175

for p in "$WIN_ESP" "$WIN_MSR" "$WIN_C"; do
  test -b "$p"
  lsblk -o NAME,PKNAME,PARTN,SIZE,FSTYPE,MOUNTPOINTS "$p"
done
swapon --show
```

After confirming that checkpoint, write the new table:

```sh
sudo sgdisk \
  --delete=1 --delete=2 --delete=3 \
  --new=1:2048:4196351 \
  --typecode=1:EF00 \
  --change-name=1:disk-samsung-ESP \
  --new=2:4196352:343046143 \
  --typecode=2:8309 \
  --change-name=2:disk-samsung-cryptroot \
  "$DISK"

sudo sgdisk --verify "$DISK"
sudo sgdisk --print "$DISK"
```

A warning that the kernel still uses the old table is not permission to format.
Refresh only the changed entries:

```sh
sudo partx --delete --nr 1:3 "$DISK"
sudo partx --add --nr 1:2 "$DISK"
sudo udevadm settle

ESP=/dev/disk/by-partlabel/disk-samsung-ESP
CRYPT=/dev/disk/by-partlabel/disk-samsung-cryptroot
test -b "$ESP"
test -b "$CRYPT"
lsblk -o NAME,START,SIZE,PARTLABEL,PARTUUID,MOUNTPOINTS "$DISK"
sudo sfdisk --json "$DISK"
```

If the refresh fails, stop and reboot into Arch through **Limine**. Resume at
verification, not at the partition-table write. Never format through stale nodes.

Compare against `samsung-before.json`: partitions 4, 5 and 6 must retain their
PARTUUIDs and exact bounds. Verify both new partitions belong to the Samsung and
have the requested bounds before continuing.

## 6. Format and mount the new system

**Destructive checkpoint:** recheck the new partitions' disk, labels and sizes.
Only these new partitions are formatted.

```sh
sudo mkfs.fat -F 32 -n NIXOS_ESP "$ESP"
sudo cryptsetup luksFormat --type luks2 "$CRYPT"
sudo cryptsetup open "$CRYPT" cryptroot
sudo mkfs.btrfs -L nixos-root /dev/mapper/cryptroot
```

Store the LUKS recovery passphrase out-of-band, not in git, a command argument or a
shell variable. Stop if a mapper named `cryptroot` already exists unexpectedly.

Ensure `/mnt` is unused before mounting:

```sh
findmnt -R /mnt || true
sudo mkdir -p /mnt
sudo mount /dev/mapper/cryptroot /mnt
for subvol in @ @nix @cache @log @tmp @images @snapshots; do
  sudo btrfs subvolume create "/mnt/$subvol"
done
sudo chattr +C /mnt/@images
sudo umount /mnt

OPTS=noatime,compress=zstd:3,ssd,discard=async,space_cache=v2
sudo mount -o "$OPTS,subvol=@" /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/{boot,nix,home,data,.snapshots}
sudo mkdir -p /mnt/var/{cache,log,tmp,lib/libvirt/images}

sudo mount -o "$OPTS,subvol=@nix"       /dev/mapper/cryptroot /mnt/nix
sudo mount -o "$OPTS,subvol=@cache"     /dev/mapper/cryptroot /mnt/var/cache
sudo mount -o "$OPTS,subvol=@log"       /dev/mapper/cryptroot /mnt/var/log
sudo mount -o "$OPTS,subvol=@tmp"       /dev/mapper/cryptroot /mnt/var/tmp
sudo mount -o "$OPTS,subvol=@images"    /dev/mapper/cryptroot /mnt/var/lib/libvirt/images
sudo mount -o "$OPTS,subvol=@snapshots" /dev/mapper/cryptroot /mnt/.snapshots
sudo chmod 1777 /mnt/var/tmp
sudo mount -o fmask=0077,dmask=0077 "$ESP" /mnt/boot

DATA=/dev/disk/by-uuid/47fa5ee2-addd-466b-b7fc-4e7d92968234
sudo mount -o "$OPTS,subvol=@home" "$DATA" /mnt/home
sudo mount -o "$OPTS,subvol=@data" "$DATA" /mnt/data
findmnt -R /mnt
```

Do not create or format anything on LinuxData. Nested subvolumes in `@home` remain
accessible automatically. Check `/mnt/home` contains your existing home before
installing.

Back up the LUKS header and record filesystem identifiers without exposing keys:

```sh
sudo cryptsetup luksHeaderBackup "$CRYPT" \
  --header-backup-file "$BACKUP/nixos-luks-header.img"
sudo chmod 0600 "$BACKUP/nixos-luks-header.img"
sudo cryptsetup luksUUID "$CRYPT"
sudo blkid /dev/mapper/cryptroot "$ESP"
```

Keep the header backup private and copy it off-machine.

## 7. Copy machine identity and chosen networks

The current configuration has [SSH identity enrollment](enroll-legion-identities.md)
enabled: sops restores the client, builder and server host keys. Copy the external
root age bootstrap key before installation:

```sh
sudo install -d -m 0700 /mnt/var/lib/sops-nix
sudo install -m 0600 /var/lib/sops-nix/key.txt /mnt/var/lib/sops-nix/key.txt
sudo cmp /var/lib/sops-nix/key.txt /mnt/var/lib/sops-nix/key.txt
```

**Only when installing a revision that predates identity enrollment**, also
preserve the old server and builder key files. Skip this block for the current
configuration:

```sh
sudo install -d -m 0755 /mnt/etc/ssh
sudo bash -c 'cp -a /etc/ssh/ssh_host_* /mnt/etc/ssh/'
sudo install -d -m 0700 /mnt/root/.ssh
sudo install -m 0600 /root/.ssh/nix-remote /mnt/root/.ssh/nix-remote
sudo cmp /etc/ssh/ssh_host_ed25519_key /mnt/etc/ssh/ssh_host_ed25519_key
sudo cmp /root/.ssh/nix-remote /mnt/root/.ssh/nix-remote
sudo ssh-keygen -lf /mnt/etc/ssh/ssh_host_ed25519_key.pub
```

Copy mutable daemon state while its owner is stopped. **Use a local terminal, not
Tailscale SSH. Bluetooth input will disconnect; use built-in or wired input.**

```sh
sudo systemctl stop tailscaled.service bluetooth.service
sudo rsync -aHAX /var/lib/tailscale /mnt/var/lib/
sudo rsync -aHAX /var/lib/bluetooth /mnt/var/lib/
sudo systemctl start bluetooth.service tailscaled.service
```

If copying fails, restart the stopped services before diagnosing. Do not run both
installations simultaneously with the copied Tailscale identity.

Create an explicit network keep-list and copy each selected profile; retaining no
profiles is also valid if you will reconnect manually:

```sh
sudo install -d -m 0700 /mnt/etc/NetworkManager/system-connections
# Replace the filename, and repeat only for selected profiles.
sudo cp -a \
  "/etc/NetworkManager/system-connections/CHOSEN-NETWORK.nmconnection" \
  /mnt/etc/NetworkManager/system-connections/

sudo ls -ld /mnt/var/lib/{tailscale,bluetooth,sops-nix}
sudo ls -l /mnt/etc/NetworkManager/system-connections/
```

### What the home already carries

`@home` is remounted as it is, so user-scoped identity needs no copy:
`~/.config/sops/age/keys.txt`, `~/.ssh/id_ed25519`, `~/.ssh/id_rsa`,
`~/.config/gh/` and `~/.local/share/keyrings/` all remain available. Back up the age
identity securely off-machine; the encrypted files in `secrets/` cannot replace a
lost decryption key. Home Manager renders the user secrets again using that key;
system secrets use `/var/lib/sops-nix/key.txt`, copied above.

NixOS reads the carried `~/.ssh/authorized_keys` alongside its declared keys in
`/etc/ssh/authorized_keys.d/saurabhj`; it neither replaces nor merges the home file.
The existing client keys therefore remain authorized.

The login keyring holds the stored GitHub credential. NixOS enables GNOME Keyring
and greetd's PAM unlock, but an agent socket or unlocked keyring is runtime state,
not something to copy. If the new login password differs from the old keyring
password, unlock the existing keyring with its old password and change its password
to match. Do not delete or reset the keyring to fix an unlock failure.

### Revoke Arch's vdirsyncer OAuth client

`vdirsyncer` and `khal` are no longer declared and the cron entry that ran them
lived on Arch's root. The Google OAuth client it used is still valid: revoke it in
the Google account's security settings, because deleting local files does not.

Never print private keys, tokens or network passwords into the execution record.

### Migrate Git configuration to Home Manager

The `git` aspect owns the preferences previously in `~/.gitconfig`, Git LFS,
delta and GitHub's credential helper. The old file takes precedence over Home
Manager's `~/.config/git/config`, so leaving it in place would retain the stale
Arch libsecret and hidden `.gh-wrapped` helper paths. Before the first activation,
back it up outside Git's automatic config search paths, then remove the original.
Do not overwrite an existing backup. Do the same for an unmanaged
`~/.config/git/config` if present; a Home Manager store link needs no manual removal.
The existing `~/.config/gh/config.yml` also becomes HM-owned: preserve it before a
standalone HM switch, or let embedded HM's configured `.backup` handling move it
aside. The generated file preserves its preferences and `co` alias.
`~/.config/gh/hosts.yml` and the keyring remain application-owned.

Interactive GitHub credentials remain in the login keyring and are not copied into
Nix configuration. After boot, verify the generated configuration and check both
the environment token and stored keyring login:

```sh
git config --global --show-origin --list
gh auth status
env -u GH_TOKEN -u GITHUB_TOKEN gh auth status
```

If the stored GitHub login fails, unlock the carried keyring first. If its token has
been revoked, renew it with `gh auth login` rather than deleting unrelated keyring
state. Do not run `gh auth setup-git` to write a second set of global helpers: the
native Home Manager module already owns them.

## 8. Install and set the login password

Install the exact output built in section 1, not a newly evaluated working tree:

```sh
sudo "$TOOLS/bin/nixos-install" \
  --root /mnt \
  --system "$SYSTEM" \
  --no-root-passwd

sudo "$TOOLS/bin/nixos-enter" --root /mnt -c '/nix/var/nix/profiles/system/sw/bin/passwd saurabhj'

sudo readlink /mnt/nix/var/nix/profiles/system
sudo ls /mnt/boot/loader/entries/
sudo efibootmgr -v
```

Stop on an installation error; do not reboot until it is resolved. Verify a new
NixOS/Linux Boot Manager entry points to the new ESP and **Limine still points to
the preserved Arch ESP**. Only then delete the two entries belonging to what this
install removed — `Windows Boot Manager`, whose ESP is gone, and `Fedora`, whose
partitions are gone. Record the listing first, and resolve each `BootNNNN` id from a
fresh one, because the firmware assigns them:

```sh
sudo efibootmgr -v
sudo efibootmgr --delete-bootnum --bootnum <id>
sudo efibootmgr -v
```

Home Manager activation can change the shared home during installation or first
boot. Close applications before installation and keep a home snapshot/backup if
rollback must include application state. Arch's partitions remain intact, but its
home configuration is not an independent copy. An unmanaged file already sitting at
a Home Manager target is renamed to `<name>.backup` by first activation instead of
aborting it, so those renames are the record of what the declarative configuration
displaced.

`--no-root-passwd` leaves root without a password, and the configuration declares
none for `saurabhj` either, so the account is locked until that `passwd` call — which
makes it the one step in this runbook that must not be skipped. sudo needs the same
password (`security.sudo.wheelNeedsPassword` is at its default), and
`users.mutableUsers` is `true`, so what you set here survives every later rebuild.
The command uses the absolute path because `nixos-enter` has no `passwd` on its
`PATH`: the setuid wrapper under `/run/wrappers` does not exist in the chroot. Do not
pass the host's `PATH` in to compensate.

Nothing has to be declared for that to keep working. The alternative is to declare
`initialHashedPassword` before installing: the activation script applies it during
`nixos-install`, so the machine comes up with a working login. Use a `$y$` (yescrypt)
hash rather than `$6$`, because the hash is world-readable in the store and in git
history.

### Recovery: no usable login

If the installed system comes up without a working login, the account exists but has
no password, and root has none either, so there is no way in from the installed
system itself. Boot NixOS media and enter it:

```sh
cryptsetup open "$CRYPT" cryptroot

mkdir -p /mnt
mount -o "$OPTS,subvol=@" /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,nix}
mount -o "$OPTS,subvol=@nix" /dev/mapper/cryptroot /mnt/nix
mount -o fmask=0077,dmask=0077 "$ESP" /mnt/boot

nixos-enter --root /mnt -c '/nix/var/nix/profiles/system/sw/bin/passwd saurabhj'
```

Set `$CRYPT`, `$ESP` and `$OPTS` again in the media's shell; they are the values from
section 6. This repeats only the mount commands — no partitioning, `luksFormat`,
`mkfs` or subvolume creation. Reboot into the installed system and confirm the
password before changing anything about the firmware entries.

## 9. Boot and verify

Close applications, sync writes and reboot. Select the new NixOS entry in the
firmware boot menu. Logging in at the greeter with the password set in section 8 is
the first check that it took; confirm `sudo` accepts the same password:

```sh
sudo -v
for target in / /nix /boot /home /data /mnt/Shared /.snapshots /var/cache /var/log \
  /var/tmp /var/lib/libvirt/images; do findmnt "$target"; done
systemctl --failed
systemctl status home-manager-saurabhj.service --no-pager
sudo tailscale status
systemctl status nix-daemon.service --no-pager
sudo test -s /var/lib/sops-nix/key.txt
sudo test -s /run/secrets/rendered/nixbuild.net.env
sudo test -s /run/secrets/niks3.api_token
test -r ~/.config/sops/age/keys.txt
test -s ~/.config/sops-nix/secrets/GITHUB_TOKEN
sudo ssh -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
  -i /run/secrets/ssh-builder dev@home-forge true
for type in ed25519 rsa ecdsa; do
  sudo ssh-keygen -lf "/run/secrets/ssh-host-$type"
done
bluetoothctl devices
nmcli connection show
sudo snapper list-configs
systemctl list-timers --all 'snapper*'

uname -r                                  # linuxPackages_latest, not the LTS default
timedatectl show -p Timezone --value      # set from GeoIP by automatic-timezoned
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager HandleLidSwitchExternalPower    # ignore
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode   # 1
command -v toggle-kbd codex opencode
sudo grep toggle-kbd-helper /etc/sudoers  # NOPASSWD for lock and unlock only
ls -l /lib64/ld-linux-x86-64.so.2         # nix-ld shim for prebuilt binaries
ls /proc/sys/fs/binfmt_misc/              # appimage registrations
git config --global --show-origin --list
ls ~/*.backup ~/.config/*.backup 2>/dev/null
```

Confirm LUKS unlock, root mounts on `cryptroot`, home/data on LinuxData, desktop,
input, audio, networking, NVIDIA, root-secret decryption, and the existing legion
tailnet identity. Check Syncthing's identity before permitting unexpected
resynchronisation. Confirm the lid is ignored on AC power (battery behaviour is
unchanged), a ZMK board appears for keypeek with its `/dev/hidraw*` node at mode
666, and a KDE Connect phone pairs over the LAN.

Run the GitHub checks from section 7 after logging in. `sudo sshd -T` lists the
selected server key paths; compare all three fingerprints with the pre-install
record. For an unenrolled revision, use `/root/.ssh/nix-remote` for the builder
check and fingerprint the copied `/etc/ssh/ssh_host_*_key.pub` files instead.

Root sops runs through NixOS activation, not a `sops-install-secrets.service` unit;
the secret-file checks above verify its output. If sops fails, verify the shared
home is mounted and the copied root age key exists with root ownership and mode
`0600`. Restore a missing key from its secured backup; do not generate a replacement,
which cannot decrypt the existing secrets. Re-run system activation and the failed
Home Manager service after correcting the key. If builder SSH fails, check
`/run/secrets/ssh-builder` is present, root-owned and mode `0400`, then verify
Tailscale connectivity and the configured host key; do not bypass host
key checking or rotate the builder identity to work around a missing local key.

The carried imperative keyboard script may shadow the Nix version. On NixOS only:

```sh
mv ~/.local/bin/toggle-kbd ~/.local/bin/toggle-kbd.arch
command -v toggle-kbd
```

Keep the standalone Arch Home Manager profile during the soak. If rolling back,
select Limine and reactivate the Arch HM generation as needed to repair shared-home
symlinks; the two installations use separate Nix stores. Restore the old keyboard
script's name if needed on Arch.

## Recovery media

If Arch cannot perform the installation, boot NixOS media and re-verify disk
identity. For a target already formatted, **do not repeat partitioning, luksFormat,
mkfs or subvolume creation**. Open the existing LUKS container and repeat only the
mount commands from section 6, then restore/verify machine state.

The built closure remains in Arch's separate store, not the live ISO's store.
Arrange a cache or copy the closure before installing from media; do not assume the
ISO can access `$SYSTEM` merely because that path existed on Arch. Use the same
recorded configuration revision. Resolve missing closure access before proceeding,
rather than starting a large build in the ISO's tmpfs.

## After successful daily use

Stop here for the soak: the freed SK hynix extent stays unpartitioned and Arch stays
bootable through Limine. Arch retirement, LUKS growth, TPM enrolment and the Windows
reinstallation are separate operations.
Before retiring Arch, capture fresh partition identities and prepare a separate
growth procedure preserving the LUKS partition's start and identity and respecting
the GPT last usable sector. Do not use the physical disk's final sector as a
partition end.

Record the installed revision, system path, backup location, filesystem identifiers,
selected network filenames, boot verification and remaining issues in the change's
Execution Record. Never record secret values.
