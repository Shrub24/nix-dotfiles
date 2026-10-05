_: {
  # Boot stays native (boot.loader.*/boot.initrd.* in the host's _hardware.nix);
  # the Arch systemManager boot config lives in modules/hosts/legion/_system.nix.
  flake.modules.nixos.boot = _: {
    boot.plymouth.enable = true;
    services.btrfs.autoScrub.enable = true;
  };
}
