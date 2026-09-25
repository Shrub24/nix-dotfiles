# Install-day disk layout for the laptop, and the source of the installed
# system's mounts: disko's NixOS module renders `fileSystems`, the LUKS
# initrd device and `swapDevices` from this device tree, so _hardware.nix
# must not restate any of them.
#
# Only `boot.loader.*` stays outside — disko creates the ESP, and systemd-boot
# installs into it, but which bootloader manages it is still host policy.
#
# Running this is destructive: `disko --mode disko` (or `nixos-anywhere`)
# wipes the named disk. The laptop is single-boot on a wiped disk, so there
# is nothing to preserve — that is precisely why the desktop's install
# (nixos-dual-boot-install) provisions by hand instead.
_:
let
  # Tuned once and shared by every subvolume so the mount options cannot
  # drift between them.
  opts = [
    "noatime"
    "compress=zstd:3"
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
in
{
  disko.devices = {
    disk.main = {
      type = "disk";
      # CONFIRM ON THE LIVE MEDIA (`lsblk -o NAME,SIZE,MODEL`): the internal
      # NVMe. A wrong value here formats the wrong device.
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          cryptroot = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              # Format-time only: disko reads this to run cryptsetup, and never
              # emits it into `boot.initrd.luks.devices`, so the installed system
              # still prompts. nixos-anywhere injects the file via
              # `--disk-encryption-keys /tmp/secret.key <local-path>`.
              passwordFile = "/tmp/secret.key";
              # `settings` is spread into `boot.initrd.luks.devices.cryptroot`
              # and read selectively by disko's own cryptsetup calls, so
              # crypttabExtraOpts reaches the installed system unchanged.
              settings = {
                allowDiscards = true;
                # Enrolment is a post-install step; the passphrase stays as
                # the fallback so a firmware reset degrades to a prompt.
                crypttabExtraOpts = [ "tpm2-device=auto" ];
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = opts;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    # x-initrd.mount so the store is up before switch-root.
                    mountOptions = opts ++ [ "x-initrd.mount" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = opts;
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = opts;
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    # `path` defaults to the subvolume name, which would put
                    # the swapfile at /swap/@swap.
                    swap.swapfile = {
                      size = "12G";
                      path = "swapfile";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
