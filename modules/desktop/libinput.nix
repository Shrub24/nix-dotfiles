_: {
  flake.modules.homeManager.libinput =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.libinput ];
    };
}
