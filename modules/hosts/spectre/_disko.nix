# Disko owns the laptop's disk: it renders `fileSystems`, the LUKS initrd
# device and `swapDevices`, so _hardware.nix must not restate them. Running
# this is destructive: `disko --mode disko` wipes the named disk.
_:
let
  # Shared by every subvolume so the mount options cannot drift.
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
      # CONFIRM ON THE LIVE MEDIA (`lsblk -o NAME,SIZE,MODEL`): a wrong value here
      # formats the wrong device.
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            # 2 GiB: ~60-70 MB per generation against a configurationLimit of
            # 20 is 1.2-1.4 GB, which a 1 GiB ESP cannot hold.
            size = "2G";
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
              # Format-time only — disko never emits it into boot.initrd.luks.devices,
              # so the installed system still prompts; nixos-anywhere injects it.
              passwordFile = "/tmp/secret.key";
              # `settings` is spread into boot.initrd.luks.devices.cryptroot, so
              # crypttabExtraOpts reaches the installed system unchanged.
              settings = {
                allowDiscards = true;
                # Enrolment is a post-install step; the passphrase stays as fallback.
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
                  # Reserved for impermanence; declaring it now avoids a subvolume
                  # create and a live-data move later. Nothing writes here yet.
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = opts;
                  };
                  # Desktop root-disk set minus @images: no VMs, and rootless
                  # podman stores under ~/.local, so these out of @ keep churn
                  # out of the root snapshots.
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = opts;
                  };
                  "@cache" = {
                    mountpoint = "/var/cache";
                    mountOptions = opts;
                  };
                  "@tmp" = {
                    mountpoint = "/var/tmp";
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
