{ primaryUser }:
{ pkgs, ... }:
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

  # Lid close on AC is a no-op; on battery logind keeps its suspend default.
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # The built-in ITE keyboard (048d:c987); toggle-kbd unbinds this interface.
  programs.toggle-kbd.usbInterface = "3-9:1.0";

  # Lenovo battery conservation mode.
  systemd.tmpfiles.rules = [
    "w /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode - - - - 1"
  ];

  # The open NVIDIA and openrazer modules must build against the kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Units only this host runs; the shared set is in notify.
  services.notify.events = {
    "niks3-auto-upload".failure = { };
    "home-manager-${primaryUser.name}".failure.severity = "critical";
    syncthing.failure.severity = "warning";
    "snapper-timeline".failure = { };
    "snapper-cleanup".failure = { };
  };

  # /data deliberately has no snapshot config: it holds only rescue images
  # and cache residue, which gain nothing from CoW snapshots.
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1h";
    configs = {
      root = snapperRoot;
      home = snapperHome;
    };
  };
}
