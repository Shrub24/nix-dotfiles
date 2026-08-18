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
      # Native services.tailscale replaces the manual systemd.packages + tailscaled
      # unit wiring: it sets up the daemon, persisted state in /var/lib/tailscale,
      # and the CLI. services.tailscale.port defaults to 41641 (matches the
      # systemManager PORT env var). openFirewall stays false - tailscale handles
      # NAT traversal without it in client mode (parity with the systemManager aspect).
      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
      };
    }

  ;
}
