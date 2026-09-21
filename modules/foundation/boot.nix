_: {
  # NixOS owns boot natively through boot.loader.* / boot.initrd.* (see
  # modules/hosts/arch/_hardware.nix). The Arch systemManager boot configuration —
  # the dracut drop-in and the Limine/snapper conf — names one machine's disk and
  # lives in that host's own raw module (modules/hosts/arch/_system.nix).
  flake.modules.nixos.boot = _: {
    boot.plymouth.enable = true;
    services.btrfs.autoScrub.enable = true;
  };
}
