_: {
  flake.modules.homeManager.mosh =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.mosh ];
    }

  ;

  flake.modules.nixos.mosh = _: {
    programs.mosh = {
      enable = true;
      openFirewall = false; # UDP range is tailnet-scoped in the network aspect
    };
  };
}
