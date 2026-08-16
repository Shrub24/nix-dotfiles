_: {
  flake.modules.homeManager.mutagen =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.mutagen ];
    }

  ;
}
