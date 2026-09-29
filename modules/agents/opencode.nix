{ inputs, ... }:
{
  flake.modules.homeManager.opencode =
    {
      config,
      pkgs,
      ...
    }:

    {
      home = {
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode ];
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
