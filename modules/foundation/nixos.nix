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
        # The fleet owns the SSH hardening (`services.ssh-baseline` turns
        # PasswordAuthentication off) and leaves who may log in to the
        # consumer — ssh.nix has no key option, and build-account.nix
        # deliberately ships the dispatch account with none. So the keys are
        # declared here, beside the account they belong to.
        #
        # Deliberate set, not a copy of any host's ~/.ssh/authorized_keys:
        # `whip` (20 auths) and `u0_a925` (7) both come from galaxy over the
        # tailnet and `admin` from a second device. The desktop's file also
        # carried u0_a818 and a windows-client key with no authentications in
        # six months, and had churned outside Nix — transcribing it would
        # ratify whatever drifted in rather than state a decision.
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINC4MMzkSTgp9ohQMY4uZay4srU7ZUcyYEz/Mi8L7q8X u0_a925@localhost"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMrzW7nXTeKqejlnIYmccciDJ4/PfjV6ek4Wvo7v86/a admin"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtAJ/Vgep5XISOIcE+bY/4jOyA4Qi6yihLPn1VJa/Xr whip"
        ];
      };
      # Private primary group (matches Arch user-private-groups, GID == UID).
      users.groups.${primaryUser.name} = {
        inherit (primaryUser) gid;
      };
    };
}
