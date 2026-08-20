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

  # NixOS translation: the systemManager aspect's resolved.conf.d mdns-disable
  # drop-in is owned natively by services.resolved on NixOS. ponytail: the
  # config-level enableResolvedMdns option is dropped - just enable resolved with
  # mDNS off (matches current `/etc` behavior). Re-add the option if a caller
  # ever needs mDNS on; avahi is the separate native knob for that.
  flake.modules.nixos.network =
    { pkgs, ... }:
    {
      services.resolved.enable = true;
      # NixOS settings attribute shape (extraConfig was removed upstream).
      services.resolved.settings.Resolve.MulticastDNS = "no";

      networking.networkmanager = {
        enable = true;
        plugins = [
          pkgs.networkmanager-openconnect
          pkgs.networkmanager-openvpn
        ];
      };
      networking.firewall.enable = true;
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };
}
