_: {
  flake.modules.homeManager.opencode =
    {
      config,
      ...
    }:

    {
      home = {
        file = {
          ".config/opencode".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/opencode";
          ".agents".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/agents";
        };
      };
    }

  ;
}
