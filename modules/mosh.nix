_: {
  flake.modules.homeManager.mosh =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.mosh ];
    }

  ;
}
