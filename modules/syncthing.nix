_: {
  flake.modules.nixos.syncthing =
    { config, ... }:
    let
      # Both the account and its home come from the projection; the NixOS eval has
      # no `home.*` options.
      primaryUser = config.currentHost.primaryUser;
      home = config.users.users.${primaryUser.name}.home;
    in
    {
      services.syncthing = {
        enable = true;
        user = primaryUser.name;
        # Reuses the existing state (identity key + config.xml); a separate data
        # dir would orphan the device identity and re-prompt every peer.
        dataDir = home;
        configDir = "${home}/.local/state/syncthing";
        # Ports are tailnet-scoped in the network aspect, not globally open.
        openDefaultPorts = false;
        overrideDevices = false;
        overrideFolders = false;
      };
    };
}
