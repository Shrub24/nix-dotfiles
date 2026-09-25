# Provisioning the laptop (`spectre`)

One-time, destructive, operator-run. Wipes `/dev/nvme0n1` and installs
`nixosConfigurations.spectre`. The desktop is the driver; the laptop only
needs to be booted into a NixOS installer with a reachable SSH host.

Companion runbook: [migrate-home-to-data-disk.md](migrate-home-to-data-disk.md)
is the desktop's migration and shares nothing with this one.

## What this creates

`disko.devices` in `modules/hosts/spectre/_disko.nix` is the source of truth;
this table is a rendering of it.

| Partition   | Size      | GPT type | Content                                         |
| ----------- | --------- | -------- | ----------------------------------------------- |
| `ESP`       | 2 GiB     | `EF00`   | FAT32, mounted `/boot`, `fmask=0077,dmask=0077` |
| `cryptroot` | remainder | `8300`   | LUKS2 named `cryptroot`, `--allow-discards`     |

Inside the container, one btrfs filesystem with five subvolumes:

| Subvolume    | Mountpoint    | Notes                                         |
| ------------ | ------------- | --------------------------------------------- |
| `@`          | `/`           |                                               |
| `@nix`       | `/nix`        | `x-initrd.mount`                              |
| `@home`      | `/home`       |                                               |
| `@snapshots` | `/.snapshots` |                                               |
| `@persist`   | `/persist`    | empty; reserved for impermanence/preservation |
| `@swap`      | `/swap`       | holds a 12 GiB `swapfile`                     |

Every subvolume carries `noatime,compress=zstd:3,ssd,discard=async,space_cache=v2`.

Three things follow from that device tree and are _not_ restated anywhere
else, because disko renders them at normal priority:

- `fileSystems` for `/`, `/.snapshots`, `/boot`, `/home`, `/nix`, `/persist`, `/swap`
- `boot.initrd.luks.devices.cryptroot.device = /dev/disk/by-partlabel/disk-main-cryptroot`
  — partlabel, not UUID, which is why nothing here captures a filesystem UUID
- `swapDevices = [ "/swap/swapfile" ]`

`_hardware.nix` keeps `boot.loader.*`, and everything else it declares
overrides facter's `mkDefault` assignments.

**Divergence from the desktop's root disk:** the desktop also carries
`@cache` → `/var/cache`, `@log` → `/var/log`, `@tmp` → `/var/tmp` and
`@images` → `/var/lib/libvirt/images`, so those churn paths fall outside its
root snapshots. The laptop has none of them, so `/var/log` and `/var/cache`
live inside `@`. Adding them later needs no repartition — `btrfs subvolume
create`, mount, and a `fileSystems` entry — but moving a live journal is
fiddlier than declaring it now.

## Preflight

If your Nix does not enable flakes by default, prefix every `nix` call below
with `--extra-experimental-features 'nix-command flakes'`.

Confirm the target disk. A wrong value formats the wrong device.

```fish
lsblk -o NAME,SIZE,MODEL
```

Confirm the flake evaluates and the report is wired:

```fish
nix eval --raw .#nixosConfigurations.spectre.config.disko.devices.disk.main.device
nix eval .#nixosConfigurations.spectre.config.hardware.facter.enable
```

`facter.json` must be committed — a report generated on the live media
describes _that_ machine once, and nothing regenerates it.

## Phase 1 — install

Runs from the desktop. `nixos-anywhere` kexecs the laptop into a clean
installer, runs disko, installs, and reboots.

```fish
# The passphrase disko formats with. Format-time only: it is never emitted
# into boot.initrd.luks.devices, so the installed system still prompts.
read --silent --prompt-str='luks passphrase: ' pw; and echo -n $pw > /tmp/secret.key; set -e pw
chmod 600 /tmp/secret.key

nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
  --flake .#spectre \
  --target-host root@<spectre-ip> \
  --disk-encryption-keys /tmp/secret.key /tmp/secret.key
```

## Phase 2 — first boot

The machine boots to a passphrase prompt, then NixOS. Verify the topology
before anything else:

```fish
findmnt / /nix /home /swap /.snapshots /boot
btrfs subvolume list /
sudo btrfs filesystem usage /
```

Expected: `/` on `subvol=@`, `/nix` on `subvol=@nix`, `/home` on
`subvol=@home`, `/persist` on `subvol=@persist`, and `/boot` on
`/dev/nvme0n1p1`. `/persist` is empty until an impermanence change claims it.

## Phase 3 — the one captured value

Hibernation needs the swapfile's physical extent, which no declaration can
know:

```fish
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

Put the number into `boot.kernelParams` in `modules/hosts/spectre/_hardware.nix`,
replacing `resume_offset=REPLACE-ON-INSTALL`, then rebuild.

Then enrol the TPM so the passphrase is not needed at every boot:

```fish
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

The declared `crypttabExtraOpts = [ "tpm2-device=auto" ]` is already in
place; enrolment is the only missing half. Keep the passphrase as the
fallback — a firmware update changes PCR 7 and drops back to the prompt.

## Phase 4 — secrets

The laptop ships `secretsEnrolled = false`: the phase-1 aspect set omits
`notify`, which registers a system secret. Enrolment is:

1. Add the host's age key as a recipient in `secrets/hosts/spectre/`.
2. Flip the phase gate in `modules/hosts/spectre.nix`.

Without it the machine is fully usable; it just cannot decrypt system
secrets.

## Rollback

There is none — the disk is wiped. Re-provisioning is re-running Phase 1.
The desktop's install (`nixos-dual-boot-install`) is the one that must stay
reversible, and it provisions by hand for that reason.
