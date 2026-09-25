{ primaryUser }:
_:
let
  snapperCommon = {
    ALLOW_GROUPS = [ ];
    ALLOW_USERS = [ ];
    BACKGROUND_COMPARISON = true;
    EMPTY_PRE_POST_CLEANUP = true;
    EMPTY_PRE_POST_MIN_AGE = 3600;
    FREE_LIMIT = 0.2;
    FSTYPE = "btrfs";
    NUMBER_CLEANUP = true;
    NUMBER_LIMIT = 50;
    NUMBER_LIMIT_IMPORTANT = 10;
    NUMBER_MIN_AGE = 3600;
    QGROUP = "";
    SPACE_LIMIT = 0.5;
    SYNC_ACL = false;
    TIMELINE_CLEANUP = true;
    TIMELINE_CREATE = true;
    TIMELINE_MIN_AGE = 3600;
  };
  snapperRoot = snapperCommon // {
    SUBVOLUME = "/";
    TIMELINE_LIMIT_DAILY = 3;
    TIMELINE_LIMIT_HOURLY = 6;
    TIMELINE_LIMIT_MONTHLY = 1;
    TIMELINE_LIMIT_QUARTERLY = 0;
    TIMELINE_LIMIT_WEEKLY = 2;
    TIMELINE_LIMIT_YEARLY = 0;
  };
  snapperHome = snapperCommon // {
    SUBVOLUME = "/home";
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_HOURLY = 3;
    TIMELINE_LIMIT_MONTHLY = 3;
    TIMELINE_LIMIT_QUARTERLY = 0;
    TIMELINE_LIMIT_WEEKLY = 0;
    TIMELINE_LIMIT_YEARLY = 0;
  };
in
{
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
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "hourly";
    configs = {
      root = snapperRoot;
      home = snapperHome;
    };
  };
}
