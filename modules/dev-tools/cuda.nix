_: {
  flake.modules.homeManager.cuda =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.cudaPackages.cudatoolkit ];
    };
}
