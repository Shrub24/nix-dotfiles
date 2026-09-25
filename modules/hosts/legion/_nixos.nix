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

  # Snapper covers the root and home subvolumes. /data only holds rescue
  # images and package/cache residue, so it deliberately has no snapshot
  # config: opaque rescue images gain nothing from CoW snapshots, and the
  # mount remains available for future bulk storage.
  services.snapper.configs = {
    root.SUBVOLUME = "/";
    home.SUBVOLUME = "/home/${primaryUser.name}";
  };
}
