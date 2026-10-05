# Never run disko against this host: the disk keeps partitions this declaration
# does not describe, so `disko --mode disko` would wipe them.
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
      # by-id, so a reordered NVMe cannot point this at the data disk. Partlabels
      # derive from the `samsung` name; the install sets exactly those.
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HDJD-00BL2_S6Z5NE0W500203";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            # 2 GiB: ~50-70 MB per generation against a configurationLimit of 20
            # overflows a 1 GiB ESP.
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
              # No TPM enrolment and no declared passphrase — it is set at format
              # time. allowDiscards lets btrfs `discard=async` reach the SSD.
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
                  # Churn paths, kept out of the root snapshots.
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
