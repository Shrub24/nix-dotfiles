_: {
  # Boot stays native (boot.loader.*/boot.initrd.* in the host's _hardware.nix).
  flake.modules.nixos.boot =
    { lib, pkgs, ... }:
    {
      boot.plymouth = {
        enable = true;
        theme = "colorful_loop";
        themePackages = [
          (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "colorful_loop" ]; })
        ];
      };

      boot.loader.timeout = 1;
      boot.consoleLogLevel = lib.mkDefault 3;
      boot.initrd.verbose = lib.mkDefault false;
      boot.kernelParams = [ "quiet" ];
      services.btrfs.autoScrub.enable = true;
    };
}
