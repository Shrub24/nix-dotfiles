{
  config,
  ...
}:
let
  # Typed primary-user topology read at the flake-parts level (B11); the greeter
  # and polkit sync derive their user/UID from it.
  primaryUser = config.topology.hosts.arch.primaryUser;
in
{
  flake.modules.systemManager.greeter =
    {
      pkgs,
      ...
    }:
    let
      noctaliaGreeterPackage = pkgs.noctalia-greeter;

      # Specialized at the feature use site (B9): uid from typed topology (B11).
      noctaliaGreeterSync = pkgs.callPackage ../../pkgs/noctalia-greeter-sync {
        inherit (primaryUser) uid;
      };

      polkitSyncRule = pkgs.writeText "50-noctalia-greeter-sync.rules" ''
        polkit.addRule(function (action, subject) {
          if (
            action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") == "${noctaliaGreeterSync}/bin/noctalia-greeter-sync" &&
            subject.user == "${primaryUser.name}" &&
            subject.local &&
            subject.active
          ) {
            return polkit.Result.YES;
          }
        });
      '';

      dbusRunSession = pkgs.writeShellApplication {
        name = "dbus-run-session";
        text = ''
          exec ${pkgs.dbus}/bin/dbus-run-session \
            --config-file=${pkgs.dbus}/share/dbus-1/session.conf "$@"
        '';
      };

      noctaliaGreeterSession = pkgs.writeShellApplication {
        name = "greetd-noctalia-session";
        runtimeInputs = [
          pkgs.cage
          dbusRunSession
          pkgs.wlr-randr
        ];
        text = ''exec ${noctaliaGreeterPackage}/bin/noctalia-greeter-session "$@"'';
      };

      niriSession = pkgs.writeText "niri.desktop" ''
        [Desktop Entry]
        Name=Niri
        Comment=A scrollable-tiling Wayland compositor
        Exec=${pkgs.niri}/bin/niri-session
        Type=Application
        DesktopNames=niri
      '';

      niriUwsmLauncher = pkgs.writeShellApplication {
        name = "niri-uwsm-session";
        # ponytail: uwsm stays on pacman until NixOS day — NixOS creates
        # /etc/profiles/per-user/<user>/bin/ with uwsm on the systemd service
        # PATH; on Arch that path doesn't exist so niri's bare-name
        # `uwsm finalize` spawn fails -> WAYLAND_DISPLAY never exported.
        text = ''
          UWSM_SILENT_START=2 exec ${pkgs.systemd}/bin/systemd-cat --identifier=niri-uwsm \
            /usr/bin/uwsm start -N "Niri (UWSM)" -D niri -e -- ${pkgs.niri}/bin/niri
        '';
      };

      niriUwsmSession = pkgs.writeText "niri-uwsm.desktop" ''
        [Desktop Entry]
        Name=Niri (UWSM)
        Comment=A scrollable-tiling Wayland compositor
        Exec=${niriUwsmLauncher}/bin/niri-uwsm-session
        Type=Application
        DesktopNames=niri;
        TryExec=/usr/bin/uwsm
      '';

      greeterToml = pkgs.writeText "greeter.toml" ''
        [user]
        default = "${primaryUser.name}"
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d /usr/share/wayland-sessions 0755 root root -"
        "L+ /usr/share/wayland-sessions/niri.desktop 0644 root root - ${niriSession}"
        "L+ /usr/share/wayland-sessions/niri-uwsm.desktop 0644 root root - ${niriUwsmSession}"
        "d /var/lib/noctalia-greeter 0755 greeter greeter -"
        "f /var/lib/noctalia-greeter/greeter.log 0664 greeter greeter -"
        "L+ /var/lib/noctalia-greeter/greeter.toml 0644 root root - ${greeterToml}"
        "L+ /usr/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy 0644 root root - ${noctaliaGreeterPackage}/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy"
      ];

      environment.etc."polkit-1/rules.d/50-noctalia-greeter-sync.rules".source = polkitSyncRule;

      environment.etc."greetd/config.toml".text = ''
        [terminal]
        vt = "next"

        [default_session]
        command = "${noctaliaGreeterSession}/bin/greetd-noctalia-session -- --user ${primaryUser.name}"
        user = "greeter"
      '';

    }

  ;

  # NixOS translation of the systemManager greeter aspect.
  # The nixpkgs-native services.displayManager.noctalia-greeter module now owns
  # the greeter.toml render (/var/lib/noctalia-greeter/greeter.toml, via tmpfiles
  # L+) and the greetd session wiring (enable + default_session.command via
  # mkDefault). The polkit sync rule, greeter.log, and wayland session desktop
  # entries stay hand-rolled here.
  # Known upstream limitation: greeter.toml is clobbered on every boot (same
  # semantics as the previous store-symlink approach — no regression).
  flake.modules.nixos.greeter =
    {
      pkgs,
      ...
    }:
    let
      noctaliaGreeterPackage = pkgs.noctalia-greeter;

      # Specialized at the feature use site (B9): uid from typed topology (B11).
      noctaliaGreeterSync = pkgs.callPackage ../../pkgs/noctalia-greeter-sync {
        inherit (primaryUser) uid;
      };

      polkitSyncRule = pkgs.writeText "50-noctalia-greeter-sync.rules" ''
        polkit.addRule(function (action, subject) {
          if (
            action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") == "${noctaliaGreeterSync}/bin/noctalia-greeter-sync" &&
            subject.user == "${primaryUser.name}" &&
            subject.local &&
            subject.active
          ) {
            return polkit.Result.YES;
          }
        });
      '';

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
      # Native nixpkgs module: own greeter.toml render + greetd session wiring.
      # extraArgs preserves the "--user" session arg; settings.user.default pins
      # the [user] default in greeter.toml. Both mechanisms mirror the old hand-
      # rolled wiring.
      services.displayManager.noctalia-greeter = {
        enable = true;
        extraArgs = [
          "--user"
          primaryUser.name
        ];
        settings.user.default = primaryUser.name;
      };

      programs.uwsm.enable = true;
      # Native UWSM compositor registration (D10): generates the
      # "Niri (UWSM)" wayland-session desktop entry, replacing the custom
      # launcher/desktop-file tmpfiles the NixOS branch used before.
      programs.uwsm.waylandCompositors.niri = {
        prettyName = "Niri";
        comment = "A scrollable-tiling Wayland compositor";
        binPath = "${pkgs.niri}/bin/niri";
      };

      # Noctalia's greeter-sync pkexec wrapper lives at /run/wrappers/bin/pkexec
      # on NixOS (D6); the polkit rule authorizing it is environment.etc below.
      security.polkit.enablePkexecWrapper = true;

      systemd.tmpfiles.rules = [
        "d /usr/share/wayland-sessions 0755 root root -"
        "L+ /usr/share/wayland-sessions/niri.desktop 0644 root root - ${niriSession}"
        "f /var/lib/noctalia-greeter/greeter.log 0664 greeter greeter -"
        "L+ /usr/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy 0644 root root - ${noctaliaGreeterPackage}/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy"
      ];

      environment.etc."polkit-1/rules.d/50-noctalia-greeter-sync.rules".source = polkitSyncRule;
    }

  ;
}
