_: {
  # The account and base-OS surface both NixOS hosts share; hostname and state
  # version are host-owned.
  flake.modules.nixos.foundation =
    { config, pkgs, ... }:
    let
      primaryUser = config.currentHost.primaryUser;
    in
    {
      # Home Manager owns user configuration; Git is also available to root.
      programs.git.enable = true;

      i18n.defaultLocale = "en_AU.UTF-8";

      # Both hosts are laptops, so the zone follows geoclue's Wi-Fi fix rather than
      # a declared value; it persists in /etc/localtime between fixes.
      services.automatic-timezoned.enable = true;

      # uv's CPython and the prebuilt rust/go/node binaries run against Nix's
      # glibc only through nix-ld; these append to the module's default set.
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

      users.users.${primaryUser.name} = {
        isNormalUser = true;
        inherit (primaryUser) uid;
        group = primaryUser.name;
        extraGroups = [ "wheel" ];
        # The fleet owns SSH hardening and offers no key option, so who may log in
        # is declared here — a deliberate set, not a copy of any host's keys.
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBqFsxbrn6SVOHXi4+LS5olKxEW8JlZ5V+irA18/586 saurabhj@arch"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINC4MMzkSTgp9ohQMY4uZay4srU7ZUcyYEz/Mi8L7q8X u0_a925@localhost"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMrzW7nXTeKqejlnIYmccciDJ4/PfjV6ek4Wvo7v86/a admin"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtAJ/Vgep5XISOIcE+bY/4jOyA4Qi6yihLPn1VJa/Xr whip"
        ];
      };
      # Private primary group (user-private-groups: GID == UID).
      users.groups.${primaryUser.name} = {
        inherit (primaryUser) gid;
      };
    };
}
