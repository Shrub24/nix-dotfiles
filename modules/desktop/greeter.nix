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
        # Match the desktop's input and pointer setup so the greeter before login
        # behaves the same way.
        settings.keyboard = {
          layout = "au,gb";
          numlock = true;
        };
        settings.cursor.size = 26;
        settings.appearance = {
          hide_logo = true;
          power_buttons_position = "bottom-right";
        };
        settings.clock.enabled = true;
        cursorTheme = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Rainbow-Modern";
        };
        # Appearance-only sync through the greeter's own polkit action; the
        # module renders the rule and enables the pkexec wrapper.
        passwordlessSyncUsers = [ primaryUser.name ];
      };

      programs.uwsm.enable = true;

      # Sync's font is resolved through fontconfig, so it must be a system font.
      fonts.packages = [ pkgs.google-fonts ];

      # greetd is the login session, so its PAM stack must unlock gnome-keyring
      # or the desktop session starts with the login keyring locked.
      security.pam.services.greetd.enableGnomeKeyring = true;

      systemd.tmpfiles.rules = [
        "f /var/lib/noctalia-greeter/greeter.log 0664 greeter greeter -"
      ];
    }

  ;
}
