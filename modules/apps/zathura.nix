_: {
  flake.modules.homeManager.zathura =
    { config, ... }:
    {
      programs.zathura = {
        enable = true;
        # Noctalia renders the palette file; this only points at it. Absolute path:
        # zathura resolves a relative include against the process cwd, not the config dir.
        extraConfig = "include ${config.xdg.configHome}/zathura/noctaliarc";
      };
    };
}
