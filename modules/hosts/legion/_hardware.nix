# What no layer provisions: the data disk's mounts (from _storage.nix) and
# the Windows-shared NTFS volume. Disko renders root mounts — do not add one.
{ primaryUser }:
{ config, lib, ... }:
let
  dataDisk = (import ./_storage.nix { inherit primaryUser; }).storage.dataDisk;
  btrfsOf = subvol: uuid: opts: {
    device = "/dev/disk/by-uuid/${uuid}";
    fsType = "btrfs";
    options = opts ++ [ "subvol=${subvol}" ];
  };
in
{
  # nixos-facter sets every fact with `mkDefault`, so the policy below wins.
  # Regenerate on the machine with:
  #   sudo nix run nixpkgs#nixos-facter -- -o modules/hosts/legion/facter.json
  hardware.facter.reportPath = lib.mkIf (builtins.pathExists ./facter.json) ./facter.json;

  # Facter would load i915 and nvidia in the initrd; the proprietary module has no
  # business there and the LUKS prompt has never needed early KMS on this machine.
  hardware.facter.detected.boot.graphics.kernelModules = [ ];

  # UEFI + systemd-boot; disko creates the ESP and its mount.
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20; # match snapper retention
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "uas"
    "sd_mod"
    "btrfs"
    "i915"
  ];
  boot.kernelModules = [
    "kvm-intel"
    "i915"
    "iwlwifi"
  ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=0"
    # zram is the only swap; zswap would stack a second compressed cache in front of it.
    "zswap.enabled=0"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.i2c.enable = true;

  # Data-disk mounts, derived from _storage.nix.
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

  # zram swap (31G on 32G RAM).
  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
  # Swap is RAM, not disk: reclaim anonymous pages eagerly and skip readahead.
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
  };
  # Disk-backed /tmp (large builds), but temporary files still end at reboot.
  boot.tmp.cleanOnBoot = true;

  # CPU: 13th Gen Intel i7-13700H.
  hardware.cpu.intel.updateMicrocode = true;

  # Hybrid Intel Iris Xe + NVIDIA RTX 4060 Max-Q; Prime offload renders on
  # the iGPU and exposes `nvidia-offload <cmd>` for the dGPU.
  services.xserver.videoDrivers = [ "nvidia" ];

  # Open module: reclocking concerns that kept this proprietary are obsolete on Ada.
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
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
