_: {
  flake.modules.homeManager.libcamera =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.libcamera ];
    };
}
