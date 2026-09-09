_: {
  flake.modules.homeManager.zathura =
    { config, ... }:
    {
      programs.zathura = {
        enable = true;
        # Noctalia renders the palette file; this only points at it. The path is
        # absolute because zathura resolves a relative include against the
        # process working directory, not the config directory.
        extraConfig = "include ${config.xdg.configHome}/zathura/noctaliarc";
      };
    };
}
