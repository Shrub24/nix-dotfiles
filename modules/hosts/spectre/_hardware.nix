# Hardware policy for the laptop. Disko owns the disk — this file must not
# declare `fileSystems`, `boot.initrd.luks.devices` or `swapDevices`, because
# disko's NixOS module renders all three from `_disko.nix` and two sources for
# one option is a conflict, not a merge.
_:
{ pkgs, ... }:
{
  # UEFI + systemd-boot, single boot: adding Windows later is a resize, not a
  # reinstall. Disko creates the ESP; which bootloader manages it stays policy.
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

  # Hibernation resumes from the @swap subvolume's 12 GiB swapfile. The LUKS
  # and btrfs UUIDs come from disko; `resume_offset` cannot — it is the
  # swapfile's physical extent, so capture it once from the installed system:
  # `btrfs inspect-internal map-swapfile -r /swap/swapfile`.
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "resume_offset=REPLACE-ON-INSTALL" ];
  boot.resumeDevice = "/dev/mapper/cryptroot";

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

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # NetworkManager owns interfaces (via the shared network aspect); no per-interface
  # DHCP here.

  nixpkgs.hostPlatform = "x86_64-linux";
}
