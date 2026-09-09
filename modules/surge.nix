_: {
  # Home Manager aspect: install the Surge CLI/TUI only. No user daemon, no
  # system-manager unit — Surge's daemon belongs to the selected NixOS target.
  flake.modules.homeManager.surge =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.surge-downloader ];
    };

  # NixOS aspect: install pkgs.surge-downloader and enable the server unit,
  # upstream SurgeDM/Surge's module. We do NOT use that upstream module because
  # it unconditionally installs its own broken self-overlay and exposes no
  # package option.
  flake.modules.nixos.surge =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.surge-downloader ];
      systemd.services.surge = {
        description = "Surge download manager server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.surge-downloader}/bin/surge server start";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}
