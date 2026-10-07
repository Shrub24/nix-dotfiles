# Disko owns the disk (see _disko.nix): it renders `fileSystems`,
# `boot.initrd.luks.devices` and `swapDevices`, so none may be declared here.
_:
{ lib, pkgs, ... }:
{
  # Generate the hardware report with:
  #   nix run nixpkgs#nixos-facter > modules/hosts/spectre/facter.json
  hardware.facter.reportPath = lib.mkIf (builtins.pathExists ./facter.json) ./facter.json;

  # UEFI + systemd-boot, single boot: Windows later is a resize, not a reinstall.
  boot.loader.systemd-boot = {
    enable = true;
    # ~50 MB per generation on the 1 GiB ESP.
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Wi-Fi loads only after switch-root: iwlmvm fails when iwlwifi sits in the initrd.
  boot.kernelModules = [ "iwlwifi" ];

  # REPLACE-ON-INSTALL resume_offset: the swapfile's physical extent, which disko
  # cannot derive — `btrfs inspect-internal map-swapfile -r /swap/swapfile`.
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "resume_offset=REPLACE-ON-INSTALL" ];
  boot.resumeDevice = "/dev/mapper/cryptroot";

  # ALC285: no Sound Open Firmware, no audio.
  hardware.firmware = [ pkgs.sof-firmware ];

  # Thunderbolt 3 dock authorisation for the two ports.
  services.hardware.bolt.enable = true;

  # This generation runs warm.
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  # REPLACE-ON-INSTALL: if the firmware exposes charge_control_end_threshold
  # (hp-wmi), declare the battery charge threshold here.

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # No per-interface DHCP: NetworkManager owns interfaces via the network aspect.
}
