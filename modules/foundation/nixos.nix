_: {
  # Host and state version are host-owned; this aspect owns the account and the
  # base-OS surface both NixOS hosts share.
  flake.modules.nixos.foundation =
    { config, pkgs, ... }:
    let
      primaryUser = config.currentHost.primaryUser;
    in
    {
      # Arch supplied /usr/bin/git; nothing on NixOS did. No config: the user's
      # git config is unmanaged and lives in the carried /home.
      programs.git.enable = true;

      # uv's python-build-standalone CPython and the prebuilt rust/go binaries
      # in ~/.local/bin, ~/.cargo/bin and ~/go/bin (plus mise's node/bun) run
      # against Nix's glibc only through nix-ld. These append to the module's
      # systemd/nix default set.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          libffi
          ncurses
          readline
          sqlite
          gdbm
          tk
          libxcb
        ];
      };

      programs.appimage = {
        enable = true;
        binfmt = true;
      };

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
        # tailnet, `admin` from a second device, and the desktop's own outbound
        # identity (modules/ssh.nix uses it as IdentityFile) so it can administer
        # the hosts it builds for. The desktop's file also carried u0_a818 and a
        # windows-client key with no authentications in six months, and had
        # churned outside Nix — transcribing it would ratify whatever drifted in
        # rather than state a decision.
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBqFsxbrn6SVOHXi4+LS5olKxEW8JlZ5V+irA18/586 saurabhj@arch"
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
