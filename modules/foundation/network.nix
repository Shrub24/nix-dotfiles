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
}
