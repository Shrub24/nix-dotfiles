{ inputs, ... }: {
  flake-file.inputs.direnv-instant = {
    url = "github:Mic92/direnv-instant";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-parts.follows = "flake-parts";
    inputs.treefmt-nix.follows = "treefmt-nix";
  };

  flake.modules.homeManager.direnv =
    {
      lib,
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
        enableFishIntegration = true;
        settings = {
          use_cache = true;
          mux_delay = 4;
        };
      };

      # Fish exports its direnv-instant state to every child, including nix-shell's
      # bash. That cache is fish syntax, so bash must not inherit it or emit it.
      programs.bash.initExtra = lib.mkBefore ''
        unset __DIRENV_INSTANT_ENV_FILE
        export DIRENV_INSTANT_SHELL=bash
      '';
    }

  ;
}
