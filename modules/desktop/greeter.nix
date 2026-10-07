_: {
  # Upstream rewrites greeter.toml on every boot; the native module owns greeter.toml
  # and the greetd wiring.
  flake.modules.nixos.greeter =
    {
      config,
      pkgs,
      ...
    }:
    let
      primaryUser = config.currentHost.primaryUser;
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

      # uwsm publishes the session entry; the greeter must not see a second one,
      # because a hand-rolled niri.desktop sorts before it and wins the default.
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
        "f /var/lib/noctalia-greeter/greeter.log 0664 greeter greeter -"
      ];
    }

  ;
}
