_: {
  flake.modules.systemManager.network =
    {
      config,
      lib,
      ...
    }:

    let
      cfg = config.networking;
    in
    {
      options.networking = {
        enableResolvedMdns = lib.mkEnableOption "mDNS in systemd-resolved" // {
          description = ''
            Enable mDNS in systemd-resolved alongside avahi-daemon.
            By default (false), resolved's mDNS is disabled to avoid conflicts with avahi.
            Only enable this if you are NOT running avahi-daemon.
          '';
          default = false;
        };
      };

      config = lib.mkIf (!cfg.enableResolvedMdns) {
        environment.etc."systemd/resolved.conf.d/99-disable-mdns.conf".text = ''
          [Resolve]
          MulticastDNS=no
        '';
      };
    }

  ;

  # NixOS owns the mdns-disable drop-in natively (services.resolved), so
  # enableResolvedMdns is dropped; re-add it if a caller ever needs mDNS on.
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
