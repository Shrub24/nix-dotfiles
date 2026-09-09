_: {
  flake.modules.homeManager.foot = {
    programs.foot = {
      enable = true;

      server.enable = true;

      # The noctalia theme template renders ~/.config/foot/themes/noctalia and
      # its hook adds this include to foot.ini (modules/desktop/noctalia.nix).
      settings.main.include = "~/.config/foot/themes/noctalia";
    };
  };
}
