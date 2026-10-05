_: {
  flake.modules.homeManager.foot = {
    programs.foot = {
      enable = true;

      server.enable = true;

      # Palette rendered by the noctalia theme template into ~/.config/foot/themes/noctalia
      # (modules/desktop/noctalia.nix); foot.ini declares the include, no hook.
      settings.main.include = "~/.config/foot/themes/noctalia";
    };
  };
}
