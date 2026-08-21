{
  config,
  ...
}:
let
  # Typed primary-user topology read at the flake-parts level; closed over into
  # the NixOS syncthing service (B11).
  primaryUser = config.topology.hosts.arch.primaryUser;
in
{
  flake.modules.homeManager.syncthing =
    { ... }:
    {
      services.syncthing = {
        enable = true;
        settings = {
          devices = {
            # Peer IDs are long-lived opaque tokens, one per synced machine.
            oci-melb-1.id = "FLMOZQR-YKNSVLV-44FOWVO-JAPWF6N-HEPM2GA-L4CCNFN-ETOWFEG-JPKYTQD";
            arch.id = "L43OT2A-IULZ4LG-YRFMARJ-EX2CDF3-ZYTXGEX-UGWAYE6-K46I3BA-3KZF2AE";
            home-forge.id = "MBPDSQR-VPJRSY7-MUP2YDM-MDVRFMQ-UMQTZCQ-GZBUQW6-LE65KVE-S2SCKAB";
          };
          folders = {
            library = {
              path = "~/Music/library";
              devices = [
                "oci-melb-1"
                "arch"
                "home-forge"
              ];
              versioning = {
                type = "simple";
                params.keep = "1";
                params.cleanoutDays = "1";
              };
            };
            quarantine = {
              path = "~/Music/quarantine";
              devices = [
                "oci-melb-1"
                "arch"
              ];
              versioning = {
                type = "simple";
                params.keep = "1";
                params.cleanoutDays = "1";
              };
            };
          };
        };
      };
    };

  flake.modules.nixos.syncthing =
    { config, ... }:
    let
      home = config.users.users.${primaryUser.name}.home;
    in
    {
      services.syncthing = {
        enable = true;
        user = primaryUser.name;
        # Reuse the live HM-rendered state (identity key + config.xml).
        dataDir = home;
        configDir = "${home}/.local/state/syncthing";
        # Ports are tailnet-scoped in the network aspect, not globally open.
        openDefaultPorts = false;
        overrideDevices = false;
        overrideFolders = false;
      };
    };
}
