{ inputs, ... }:
{
  flake.modules.homeManager.herdr =
    { config, pkgs, ... }:
    {
      programs.herdr.package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;

      xdg.configFile."herdr".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/herdr";
    };
}
