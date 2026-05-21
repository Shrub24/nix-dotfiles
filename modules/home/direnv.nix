{
  inputs,
  ...
}:
{
  imports = [ inputs.direnv-instant.homeModules.direnv-instant ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
    silent = true;
    config = {
      global = {
        load_dotenv = true;
        strict_env = false;
        warn_timeout = "30s";
      };
    };
  };

  programs.direnv-instant = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      use_cache = true;
      mux_delay = 4;
    };
  };
}
