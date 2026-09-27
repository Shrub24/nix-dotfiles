_: {
  # UoM GlobalProtect. The published install guide ships the proprietary Palo
  # Alto agent, which is not packaged on NixOS; openconnect's own GP stack is —
  # `openconnect --protocols` lists `gp` ("Compatible with Palo Alto Networks
  # (PAN) GlobalProtect SSL VPN") and the NetworkManager plugin we already
  # install advertises the same, with `protocol` as a settable data key. So the
  # connection is a declarative NetworkManager profile and nothing more: the
  # portal and protocol are configuration, the Okta hand-off is the browser's.
  #
  # On Arch this profile is not in play — NetworkManager there is Arch's own,
  # and the connection is set up imperatively.
  flake.modules.nixos.globalprotect = _: {
    networking.networkmanager.ensureProfiles.profiles.globalprotect = {
      connection = {
        id = "UoM GlobalProtect";
        type = "vpn";
      };

      # Keys land in the [vpn] section of the rendered keyfile; `address` is
      # the portal, and openconnect discovers the gateway from it.
      vpn = {
        service-type = "org.freedesktop.NetworkManager.openconnect";
        address = "vpn.unimelb.edu.au";
        protocol = "gp";
      };
    };
  };
}
