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
      # Mode 0 is 80x25: on a 2560x1600 panel the firmware's kept text mode is tiny.
      boot.loader.systemd-boot.consoleMode = "0";
      boot.consoleLogLevel = lib.mkDefault 3;
      boot.initrd.verbose = lib.mkDefault false;
      boot.kernelParams = [ "quiet" ];
      services.btrfs.autoScrub.enable = true;
    };
}
