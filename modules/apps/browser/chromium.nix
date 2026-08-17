_: {
  flake.modules.homeManager.chromium =
    { pkgs, ... }:
    {
      programs.chromium = {
        enable = true;
        package = pkgs.chromium;
      };
    };
}
