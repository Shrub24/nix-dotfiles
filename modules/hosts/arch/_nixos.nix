{ lib, ... }: {
  imports = [ ./_hardware.nix ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.11";
  networking.hostName = "arch";
  users.users.saurabhj = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # Host-local unfree allowlist. _hardware.nix pulls the (unfree) nvidia driver
  # for the RTX 4060; NixOS toplevel eval needs this. NOT in an aspect because the
  # same aspects are shared with the VM test node, where nixpkgs.config is read-only.
  # ponytail: whole `nvidia` prefix allowed since the driver/tooling closure
  # (nvidia-x11, -settings, -kernel-modules, -persistenced, ...) is uniformly unfree.
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    (lib.hasPrefix "nvidia" (lib.getName pkg))
    || builtins.elem (lib.getName pkg) [
      "cuda_nvml_dev"
    ];
}
