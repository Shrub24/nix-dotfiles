_: {
  flake.modules.homeManager.zathura =
    { pkgs, ... }:
    {
      programs.zathura = {
        enable = true;
        # ponytail: pkgs.zathura is the withPlugins wrapper; pdf-mupdf is the
        # default, so no extra plugin wiring needed.
      };
    };
}
