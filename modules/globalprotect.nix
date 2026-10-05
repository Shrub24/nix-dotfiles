_: {
  # The official Palo Alto agent is unpackaged on NixOS; openconnect's `gp`
  # protocol backs this declarative profile. On Arch the profile is imperative.
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
