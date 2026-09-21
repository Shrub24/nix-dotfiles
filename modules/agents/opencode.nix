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
          # The litellm provider overlay (opencode-litellm.json, injected via
          # OPENCODE_CONFIG) is parked 2026-09-20 while the litellm gateway is
          # disabled; opencode uses its own opencode-omniroute provider.
        };
      };
    }

  ;
}
