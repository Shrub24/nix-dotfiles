# Regenerate on NixOS install day with `nixos-generate-config --root /mnt`, then
# hand-edit down to this minimal form. by-uuid is preferred over by-partlabel
# because partlabels contain spaces ("EFI system partition").
{ primaryUser }:
{ config, ... }:
let
  # The data disk's topology, stated once. /home currently has no NixOS
  # declaration (the Arch host mounts it via fstab), and the data mount
  # still names its pre-migration subvolume; both are prewired here for the
  # bare-metal install and realized post-migration.
  storage = import ./_storage.nix { inherit primaryUser; };
  dataDisk = storage.storage.dataDisk;
  btrfsOf = subvol: uuid: opts: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "btrfs";
    options = opts ++ [ "subvol=${subvol}" ];
  };
  rootOpts = [
    "noatime"
    "compress=zstd:3"
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
in
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
  boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];

  hardware.enableRedistributableFirmware = true;
  hardware.i2c.enable = true;

  # File systems (from /proc/mounts on Arch).
  # / and /nix are the same btrfs partition with different subvolumes.
  fileSystems."/" = btrfsOf "@" "35eb40c3-6466-4e66-ad20-9b7da9140992" rootOpts;

  fileSystems."/nix" = btrfsOf "@nix" "35eb40c3-6466-4e66-ad20-9b7da9140992" rootOpts;

  # Home lives on the data disk (see _storage.nix), not on the root
  # partition's own @home subvolume — the Arch host migrated there first.
  fileSystems."/home" = btrfsOf dataDisk.homeSubvol dataDisk.uuid dataDisk.commonOptions;

  # Bulk subvolume replacing a top-level /mnt/LinuxData mount.
  fileSystems."/data" = btrfsOf dataDisk.dataSubvol dataDisk.uuid dataDisk.commonOptions;

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
      "nofail"
      "uid=${toString primaryUser.uid}"
      "gid=${toString primaryUser.gid}"
      "dmask=022"
      "fmask=022"
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
  # Prime offload mode: iGPU renders by default; dGPU on demand via
  # `nvidia-offload <cmd>`.
  services.xserver.videoDrivers = [ "nvidia" ];

  # Open module: reclocking concerns that kept this proprietary are obsolete on Ada.
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # important for laptop power states
    powerManagement.finegrained = true; # RTX 4060 supports fine-grained
    open = true;
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
