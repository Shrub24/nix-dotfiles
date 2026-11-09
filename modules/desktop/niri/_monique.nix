{ moniquePackage }:
{
  systemd.user.services.moniqued = {
    Unit = {
      Description = "Monique daemon - Auto-apply monitor profiles on hotplug";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${moniquePackage}/bin/moniqued";
      Restart = "on-failure";
      RestartSec = "5";
    };

    # Monique writes Niri's monitors.kdl; other UWSM sessions have their own display tooling.
    Install.WantedBy = [ "wayland-wm@niri.service" ];
  };

  home.packages = [ moniquePackage ];
}
