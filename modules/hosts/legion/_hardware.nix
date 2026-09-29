# Hardware policy for the desktop. Disko owns the install target — the ESP, the
# LUKS container and the root subvolumes declared in _disko.nix — and renders
# their `fileSystems` and `boot.initrd.luks.devices`, so this file must not
# declare a root-disk mount. What it declares instead is what no layer
# provisions: the data disk's own mounts, derived from _storage.nix, and the
# Windows-shared NTFS volume.
{ primaryUser }:
{ config, ... }:
let
  dataDisk = (import ./_storage.nix { inherit primaryUser; }).storage.dataDisk;
  btrfsOf = subvol: uuid: opts: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "btrfs";
    options = opts ++ [ "subvol=${subvol}" ];
  };
in
{
  # UEFI + systemd-boot. Disko creates the ESP at the head of the Samsung disk
  # and declares its mount; which bootloader manages it is still host policy.
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

  # Home and bulk data live on the data disk, whose UUID and subvolume names
  # _storage.nix owns; the root install changes nothing about that disk.
  fileSystems."/home" = btrfsOf dataDisk.homeSubvol dataDisk.uuid dataDisk.commonOptions;

  fileSystems."/data" = btrfsOf dataDisk.dataSubvol dataDisk.uuid dataDisk.commonOptions;

  # Secondary NTFS shared with Windows; a missing partition must not block boot.
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
}
