_: {
  # Boot stays native (boot.loader.*/boot.initrd.* in the host's _hardware.nix).
  flake.modules.nixos.boot =
    { lib, pkgs, ... }:
    {
      boot.plymouth = {
        enable = true;
        theme = "load_unload";
        themePackages = [ pkgs.nixos-boot ];
      };

      boot.loader.timeout = 1;
      boot.consoleLogLevel = lib.mkDefault 3;
      boot.initrd.verbose = lib.mkDefault false;
      boot.kernelParams = [ "quiet" ];
      services.btrfs.autoScrub.enable = true;
    };
}
