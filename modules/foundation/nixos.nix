_: {
  # Host and state version are host-owned; this aspect owns only the account.
  flake.modules.nixos.foundation =
    { config, ... }:
    let
      primaryUser = config.currentHost.primaryUser;
    in
    {
      # NixOS owns the account; Home Manager owns its home configuration.
      users.users.${primaryUser.name} = {
        isNormalUser = true;
        inherit (primaryUser) uid;
        group = primaryUser.name;
        extraGroups = [ "wheel" ];
      };
      # Private primary group (matches Arch user-private-groups, GID == UID).
      users.groups.${primaryUser.name} = {
        inherit (primaryUser) gid;
      };
    };
}
