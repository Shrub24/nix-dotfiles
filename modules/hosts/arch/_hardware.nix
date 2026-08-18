# Hand-rolled from live system introspection on 2026-08-18.
# Sources: lsblk, /proc/mounts, lspci, lscpu, timedatectl, /dev/disk/by-uuid.
# On NixOS install day, can be regenerated via `nixos-generate-config --root /mnt`
# then hand-edited down to this minimal form. by-uuid is preferred over
# by-partlabel because partlabels contain spaces ("EFI system partition").
{ config, ... }:
{
  # UEFI + systemd-boot (existing 2G vfat /boot partition on nvme1n1p6).
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20; # match snapper retention
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Kernel modules: stock + btrfs + nvme + intel i915 + nvidia + iwlwifi.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "uas"
    "sd_mod"
    "btrfs"
    "intel_agc"
    "i915"
    "iwlwifi"
  ];
  boot.initrd.kernelModules = [ "iwlwifi" ];
  boot.kernelModules = [
    "kvm-intel"
    "i915"
    "iwlwifi"
  ];
  boot.extraModulePackages = [ ];

  # File systems (from /proc/mounts on Arch).
  # / and /nix are the same btrfs partition with different subvolumes.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/35eb40c3-6466-4e66-ad20-9b7da9140992";
    fsType = "btrfs";
    options = [
      "noatime"
      "compress=zstd:3"
      "ssd"
      "discard=async"
      "space_cache=v2"
      "subvol=@"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/35eb40c3-6466-4e66-ad20-9b7da9140992";
    fsType = "btrfs";
    options = [
      "noatime"
      "compress=zstd:3"
      "ssd"
      "discard=async"
      "space_cache=v2"
      "subvol=@nix"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7EA9-D01C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # Secondary NTFS shared with Windows dual-boot.
  fileSystems."/mnt/Shared" = {
    device = "/dev/disk/by-uuid/2EBA15A2BA15681B";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "dmask=022"
      "fmask=022"
    ];
  };

  # Secondary btrfs data partition.
  fileSystems."/mnt/LinuxData" = {
    device = "/dev/disk/by-uuid/47fa5ee2-addd-466b-b7fc-4e7d92968234";
    fsType = "btrfs";
    options = [
      "noatime"
      "compress=zstd:3"
      "ssd"
      "discard=async"
    ];
  };

  # zram swap (31G on 32G RAM - matches current Arch setup).
  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  # CPU: 13th Gen Intel i7-13700H.
  hardware.cpu.intel.updateMicrocode = true;

  # Hybrid graphics: Intel Iris Xe (iGPU) + NVIDIA RTX 4060 Max-Q (dGPU).
  # Use proprietary nvidia driver (RTX 4060 is Ada Lovelace; the open module
  # needs Turing+, works on Ada but missing reclocking for full perf).
  # Prime offload mode: iGPU renders by default; dGPU on demand via
  # `nvidia-offload <cmd>`.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # important for laptop power states
    powerManagement.finegrained = true; # RTX 4060 supports fine-grained
    open = false; # proprietary; open module lacks reclocking for full perf
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Reverse PRIME not needed - iGPU is the default.
    };
  };

  # Timezone (matches current Arch: Australia/Melbourne, AEST +1000).
  time.timeZone = "Australia/Melbourne";
}
