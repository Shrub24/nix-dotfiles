_: {
  flake.modules.homeManager.fractal =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fractal ];
    };
}
