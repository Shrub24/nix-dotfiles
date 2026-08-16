_: {
  flake.modules.homeManager.tailscale =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.tailscale ];
    }

  ;

  flake.modules.systemManager.tailscale =
    { pkgs, ... }:
    {
      systemd.packages = [ pkgs.tailscale ];
      systemd.services.tailscaled = {
        wantedBy = [ "multi-user.target" ];
        environment.PORT = "41641";
      };
    }

  ;
}
