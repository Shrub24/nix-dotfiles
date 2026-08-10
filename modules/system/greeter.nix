{
  inputs,
  pkgs,
  ...
}:
let
  noctaliaGreeterPackage =
    inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;

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
    text = ''
      exec ${pkgs.systemd}/bin/systemd-cat --identifier=niri-uwsm \
        ${pkgs.uwsm}/bin/uwsm start -N "Niri (UWSM)" -D niri -e -- ${pkgs.niri}/bin/niri
    '';
  };

  niriUwsmSession = pkgs.writeText "niri-uwsm.desktop" ''
    [Desktop Entry]
    Name=Niri (UWSM)
    Comment=A scrollable-tiling Wayland compositor
    Exec=${niriUwsmLauncher}/bin/niri-uwsm-session
    Type=Application
    DesktopNames=niri;
    TryExec=${pkgs.uwsm}/bin/uwsm
  '';

  greeterToml = pkgs.writeText "greeter.toml" ''
    [user]
    default = "saurabhj"
  '';
in
{
  systemd.tmpfiles.rules = [
    "d /usr/share/wayland-sessions 0755 root root -"
    "C+ /usr/share/wayland-sessions/niri.desktop 0644 root root - ${niriSession}"
    "C+ /usr/share/wayland-sessions/niri-uwsm.desktop 0644 root root - ${niriUwsmSession}"
    "d /var/lib/noctalia-greeter 0755 greeter greeter -"
    "f /var/lib/noctalia-greeter/greeter.log 0664 greeter greeter -"
    "C+ /var/lib/noctalia-greeter/greeter.toml 0644 root root - ${greeterToml}"
  ];

  environment.etc."greetd/config.toml".text = ''
    [terminal]
    vt = "next"

    [default_session]
    command = "${noctaliaGreeterSession}/bin/greetd-noctalia-session"
    user = "greeter"
  '';

  environment.etc."polkit-1/rules.d/50-noctalia-greeter.rules".text = ''
    polkit.addRule(function(action, subject) {
      if (
        action.id == "org.noctalia.greeter.apply-appearance" &&
        subject.user == "saurabhj" &&
        subject.local &&
        subject.active
      ) {
        return polkit.Result.YES;
      }
    });
  '';
}
