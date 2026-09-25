# Install-day disk layout, captured as a disko configuration. NOT imported
# into any host composition: disko would try to manage the live system. The
# dual-boot changes (nixos-dual-boot-install for this host, add-spectre-host
# for the laptop) import it during partitioning and never again.
#
# Facts derive from _storage.nix where they overlap (data-disk UUID,
# subvolume names) so the capture and the fileSystems cannot drift. The
# root disk's UUID is stated here only — it is boot-critical and the
# fileSystems block in _hardware.nix already owns it for the consuming
# configuration; regenerating the disk layout and reading it are different
# acts.
#
# Partition tables mirror the live disks (blkid, 2026-09): nvme0n1p5 is the
# root btrfs with @, @nix, @cache, @log, @tmp, @images, @home (legacy),
# @snapshots; nvme1n1p7 is the data btrfs. Windows keeps p1–p4/p6 on the
# root disk and p2–p4 on the data disk; /boot is nvme1n1p6's vfat, /boot is
# where the EFI system partition lives on install day — see
# nixos-dual-boot-install for the ESP/limine decision.
{ primaryUser }:
let
  storage = import ./_storage.nix { inherit primaryUser; };
  d = storage.storage.dataDisk;
in
{
  # asserted by the change's verification task: this renders exactly the
  # subvolume set _storage.nix names for the data disk.
  disko.devices = {
    disk.nvme0n1 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          # p1–p4, p6: Windows + ESP (kept, never formatted by disko).
          root = {
            # p5
            type = "8300";
            start = "…"; # resolved at install time from the existing table
            content = {
              type = "btrfs";
              # The existing filesystem is kept, not created: disko formats
              # only with --dangerous mode, and install day uses the
              # existing subvolume set — @ moves to the head of this list.
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "noatime"
                    "compress=zstd:3"
                    "ssd"
                    "discard=async"
                    "space_cache=v2"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "noatime"
                    "compress=zstd:3"
                    "ssd"
                    "discard=async"
                    "space_cache=v2"
                    "x-initrd.mount"
                  ];
                };
              };
            };
          };
        };
      };
    };
    disk.nvme1n1 = {
      type = "disk";
      device = "/dev/nvme1n1";
      content = {
        type = "gpt";
        partitions = {
          data = {
            # p7
            type = "8300";
            content = {
              type = "btrfs";
              subvolumes = {
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = d.commonOptions;
                };
                "@data" = {
                  inherit (d) mountpoint;
                  mountOptions = d.commonOptions;
                };
              };
            };
          };
        };
      };
    };
  };
}
