# The install target's disk layout, and the source of the installed system's
# root mounts: imported through disko's NixOS module, which renders
# `fileSystems` and `boot.initrd.luks.devices` from this declaration — so
# _hardware.nix declares no root-disk mount.
#
# Only the disk the install provisions appears here. The data disk does not:
# this install never partitions it, and its mounts derive by UUID from
# _storage.nix instead of from a disko-rendered by-partlabel device.
#
# Never run disko against this host. The Samsung keeps partitions this
# declaration does not describe — Arch through the soak, and the Windows
# remnants until it ends — so `disko --mode disko` would wipe them. The
# declaration is the settled layout (2 GiB ESP, then the rest of the disk as
# LUKS); the soak's shorter LUKS extent is an intermediate that the partlabels
# and the mapper name below do not depend on.
_:
let
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
    disk.samsung = {
      type = "disk";
      # by-id, so a reordered NVMe cannot point this at the data disk. The
      # partlabels derive from the `samsung` name — disk-samsung-ESP and
      # disk-samsung-cryptroot — and the install sets exactly those when it
      # creates the partitions; nothing in the system names a filesystem UUID.
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00BL2_S6Z5NE0W500203";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            # 2 GiB: ~50-70 MB per generation against a configurationLimit of
            # 20 overflows a 1 GiB ESP.
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
              # `settings` is spread into boot.initrd.luks.devices.cryptroot.
              # Discards pass through so the btrfs `discard=async` mount option
              # reaches the SSD. No TPM enrolment: the passphrase is the only
              # key, and it is set at format time, never declared here.
              settings = {
                allowDiscards = true;
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
                    mountOptions = opts;
                  };
                  # The churn paths keep their own subvolumes so they stay out
                  # of the root snapshots.
                  "@cache" = {
                    mountpoint = "/var/cache";
                    mountOptions = opts;
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = opts;
                  };
                  "@tmp" = {
                    mountpoint = "/var/tmp";
                    mountOptions = opts;
                  };
                  "@images" = {
                    mountpoint = "/var/lib/libvirt/images";
                    mountOptions = opts;
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = opts;
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
