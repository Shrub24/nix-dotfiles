_: {
  # Upstream rewrites greeter.toml on every boot; the native module owns greeter.toml
  # and the greetd wiring, while the desktop entries stay hand-rolled here.
  flake.modules.nixos.greeter =
    {
      config,
      pkgs,
      ...
    }:
    let
      primaryUser = config.currentHost.primaryUser;

      niriSession = pkgs.writeText "niri.desktop" ''
        [Desktop Entry]
        Name=Niri
        Comment=A scrollable-tiling Wayland compositor
        Exec=${pkgs.niri}/bin/niri-session
        Type=Application
        DesktopNames=niri
      '';
    in
    {
      # extraArgs preserves the "--user" session arg; settings.user.default pins
      # greeter.toml's [user] default.
      services.displayManager.noctalia-greeter = {
        enable = true;
        extraArgs = [
          "--user"
          primaryUser.name
        ];
        settings.user.default = primaryUser.name;
        # Appearance-only sync through the greeter's own polkit action; the
        # module renders the rule and enables the pkexec wrapper.
        passwordlessSyncUsers = [ primaryUser.name ];
      };

      programs.uwsm.enable = true;
      programs.uwsm.waylandCompositors.niri = {
        prettyName = "Niri";
        comment = "A scrollable-tiling Wayland compositor";
        binPath = "${pkgs.niri}/bin/niri";
      };

      # greetd is the login session, so its PAM stack must unlock gnome-keyring
      # or the desktop session starts with the login keyring locked.
      security.pam.services.greetd.enableGnomeKeyring = true;

      systemd.tmpfiles.rules = [
        "d /usr/share/wayland-sessions 0755 root root -"
        "L+ /usr/share/wayland-sessions/niri.desktop 0644 root root - ${niriSession}"
        "f /var/lib/noctalia-greeter/greeter.log 0664 greeter greeter -"
      ];
    }

  ;
}
