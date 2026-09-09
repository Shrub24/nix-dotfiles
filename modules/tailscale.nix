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

  flake.modules.nixos.tailscale =
    { pkgs, ... }:
    {
      # openFirewall stays false: tailscale handles NAT traversal in client mode,
      # matching the systemManager aspect. services.tailscale.port defaults to
      # 41641, the same value the systemManager aspect pins.
      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
      };
    }

  ;
}
