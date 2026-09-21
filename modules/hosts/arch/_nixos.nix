{ primaryUser }: { ... }: {
  imports = [ (import ./_hardware.nix { inherit primaryUser; }) ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.11";
  networking.hostName = "shrub";
  i18n.defaultLocale = "en_AU.UTF-8";

  # Snapper configs name this machine's subvolumes; the shared NixOS boot aspect
  # only enables plymouth and btrfs scrub.
  services.snapper.configs = {
    root.SUBVOLUME = "/";
    home.SUBVOLUME = "/home/${primaryUser.name}";
    data.SUBVOLUME = "/mnt/LinuxData";
  };
}
