_: {
  flake.modules.nixos.network =
    { pkgs, ... }:
    let
      webServices = (import ../../lib/web-services.nix { inherit (pkgs) lib; }).services;
    in
    {
      services.resolved.enable = true;
      services.resolved.settings.Resolve.MulticastDNS = "no";

      # nixos-facter's detected-DHCP module sets networking.useDHCP on every
      # physical interface, which fights NetworkManager; plain priority wins.
      hardware.facter.detected.dhcp.enable = false;

      networking.networkmanager = {
        enable = true;
        plugins = [
          pkgs.networkmanager-openconnect
          pkgs.networkmanager-openvpn
        ];
      };
      networking.firewall.enable = true;
      # Tailnet-scoped exposure only; the global firewall stays closed.
      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [
          22000 # syncthing data (relay/TCP)
          webServices.web-catalog.port
        ];
        allowedUDPPorts = [
          22000 # syncthing QUIC
          21027 # syncthing local discovery
        ];
        allowedUDPPortRanges = [
          {
            from = 60000;
            to = 61000; # mosh
          }
        ];
      };
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };
}
