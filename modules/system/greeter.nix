{ pkgs, ... }:
let
  noctaliaGreeterSession = pkgs.writeShellApplication {
    name = "greetd-noctalia-session";
    runtimeInputs = [
      pkgs.cage
      pkgs.dbus
      pkgs.wlr-randr
    ];
    text = ''exec ${pkgs.noctalia-greeter}/bin/noctalia-greeter-session "$@"'';
  };

  niriSession = pkgs.writeText "niri.desktop" ''
    [Desktop Entry]
    Name=Niri
    Comment=A scrollable-tiling Wayland compositor
    Exec=${pkgs.niri}/bin/niri-session
    Type=Application
    DesktopNames=niri
  '';

  niriUwsmSession = pkgs.writeText "niri-uwsm.desktop" ''
    [Desktop Entry]
    Name=Niri (UWSM)
    Comment=A scrollable-tiling Wayland compositor
    Exec=${pkgs.uwsm}/bin/uwsm start -N "Niri (UWSM)" -D niri -e -- ${pkgs.niri}/bin/niri
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
}
