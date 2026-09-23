{ primaryUser }: { ... }: {
  imports = [ (import ./_hardware.nix { inherit primaryUser; }) ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.11";
  networking.hostName = "legion";
  i18n.defaultLocale = "en_AU.UTF-8";

  # Failure registrations for units only this host runs; the shared set lives
  # in flake.modules.nixos.notify.
  services.notify.events = {
    "niks3-auto-upload".failure = { };
    "home-manager-${primaryUser.name}".failure.severity = "critical";
    syncthing.failure.severity = "warning";
  };

  # Snapper configs name this machine's subvolumes; the shared NixOS boot aspect
  # only enables plymouth and btrfs scrub.
  services.snapper.configs = {
    root.SUBVOLUME = "/";
    home.SUBVOLUME = "/home/${primaryUser.name}";
    data.SUBVOLUME = "/mnt/LinuxData";
  };
}
