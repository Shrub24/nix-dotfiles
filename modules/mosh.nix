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

    # Load-bearing, not a default: nixpkgs defaults `openFirewall` to true and
    # the fleet aspect leaves it alone, so without this the UDP range is opened
    # globally rather than on the tailnet.
    programs.mosh.openFirewall = false;
  };
}
