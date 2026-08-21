{
  config,
  ...
}:
let
  # Typed primary-user topology read at the flake-parts level; foundation is a
  # shared NixOS aspect, so it closes the topology value over into the module.
  primaryUser = config.topology.hosts.arch.primaryUser;
in
{
  flake.modules.nixos.foundation = {
    system.stateVersion = "26.11";
    networking.hostName = "shrub";
    # NixOS owns the account; Home Manager owns its home configuration.
    users.users.${primaryUser.name} = {
      isNormalUser = true;
      uid = primaryUser.uid;
      group = primaryUser.name;
      extraGroups = [ "wheel" ];
    };
    # Private primary group (matches Arch user-private-groups, GID == UID).
    users.groups.${primaryUser.name} = {
      gid = primaryUser.gid;
    };
  };
}
