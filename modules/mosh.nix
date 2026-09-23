{ inputs, ... }:
{
  flake.modules.homeManager.mosh =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.mosh ];
    }

  ;

  flake.modules.nixos.mosh = _: {
    imports = [ inputs.nix-fleet.modules.nixos.mosh ];

    # Explicit because it is a firewall stance, not a default: the UDP range is
    # tailnet-scoped in the network aspect.
    programs.mosh.openFirewall = false;
  };
}
