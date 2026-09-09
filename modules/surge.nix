_: {
  flake.modules.homeManager.surge =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.surge-downloader ];
    };

  # The upstream SurgeDM/Surge module is not used: it unconditionally installs
  # its own self-overlay and exposes no package option.
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
