# Regenerate on install day with `nixos-generate-config --root /mnt`, then hand-edit
# down to this minimal form: every REPLACE-ON-INSTALL below comes from the installed
# disk, and by-uuid beats by-partlabel because partlabels contain spaces.
_:
{ pkgs, ... }:
{
  # UEFI + systemd-boot, single boot: adding Windows later is a resize, not a
  # reinstall.
  boot.loader.systemd-boot = {
    enable = true;
    # ~50 MB per generation on the 1 GiB ESP.
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Kernel modules: stock + btrfs + nvme + i915 + iwlwifi.
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
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Hibernation: resume from the @swap subvolume's 12 GiB swapfile.
  # REPLACE-ON-INSTALL: resume = the unlocked btrfs UUID (blkid after opening
  # /dev/mapper/cryptroot); resume_offset = `btrfs inspect-internal map-swapfile
  # -r /swap/swapfile` in the installed system.
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [
    "resume=UUID=REPLACE-ON-INSTALL"
    "resume_offset=REPLACE-ON-INSTALL"
  ];

  hardware.enableRedistributableFirmware = true;
  # ALC285: no Sound Open Firmware, no audio.
  hardware.firmware = [ pkgs.sof-firmware ];

  # Ice Lake microcode.
  hardware.cpu.intel.updateMicrocode = true;

  # Thunderbolt 3 dock authorisation for the two ports.
  services.hardware.bolt.enable = true;

  # This generation runs warm.
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  # Charge threshold where the firmware exposes it (hp-wmi).
  # REPLACE-ON-INSTALL: confirm the battery exposes charge_control_end_threshold;
  # if it does, declare the threshold here rather than in a shared aspect.

  # 1 GiB ESP + one LUKS2 container with btrfs inside.
  # REPLACE-ON-INSTALL: all four UUIDs below come from the installed disk.
  boot.initrd.luks.devices."cryptroot" = {
    # REPLACE-ON-INSTALL: the LUKS partition's by-partuuid.
    device = "/dev/disk/by-partuuid/REPLACE-ON-INSTALL";
    # TPM2 enrolment adds a keyslot alongside the passphrase, which stays as the
    # fallback so a firmware reset degrades to a prompt.
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/boot" = {
    # REPLACE-ON-INSTALL: the ESP's by-partuuid.
    device = "/dev/disk/by-partuuid/REPLACE-ON-INSTALL";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/" = {
    # REPLACE-ON-INSTALL: the unlocked btrfs filesystem's by-uuid.
    device = "/dev/disk/by-uuid/REPLACE-ON-INSTALL";
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
    # REPLACE-ON-INSTALL: same filesystem UUID as "/".
    device = "/dev/disk/by-uuid/REPLACE-ON-INSTALL";
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

  fileSystems."/home" = {
    # REPLACE-ON-INSTALL: same filesystem UUID as "/".
    device = "/dev/disk/by-uuid/REPLACE-ON-INSTALL";
    fsType = "btrfs";
    options = [
      "noatime"
      "compress=zstd:3"
      "ssd"
      "discard=async"
      "space_cache=v2"
      "subvol=@home"
    ];
  };

  fileSystems."/swap" = {
    # REPLACE-ON-INSTALL: same filesystem UUID as "/".
    device = "/dev/disk/by-uuid/REPLACE-ON-INSTALL";
    fsType = "btrfs";
    options = [
      "noatime"
      "nodatacow"
      "subvol=@swap"
    ];
  };

  # Declared WITHOUT `size` on purpose: nixpkgs' swapfile service rewrites the
  # file when a declared size differs from the on-disk one, moving the extents
  # `resume_offset` points at and silently breaking hibernation resume.
  swapDevices = [ { device = "/swap/swapfile"; } ];

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # NetworkManager owns interfaces (via the shared network aspect); no per-interface
  # DHCP here.

  nixpkgs.hostPlatform = "x86_64-linux";
}
