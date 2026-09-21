{
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  # Milestone 2 flips the primary name to "nvim". Until the port is a
  # daily-driver substitute it installs as nvim-nix, so the pacman nvim at
  # /usr/bin/nvim keeps working unchanged.
  config.binName = "nvim-nix";
  config.settings.aliases = [ ];
  config.settings.dont_link = true;

  # The Lua tree beside this file. Includes and the runtimepath are generated
  # from here; nothing outside this directory is read at runtime.
  config.settings.config_directory = ./.;

  config.specs = import ./_plugins.nix {
    inherit pkgs;
    custom = import ./_custom.nix { inherit pkgs; };
  };

  # Binaries on the wrapped editor's PATH. Spec-level `runtimePkgs` needs a
  # specMods declaration; the module-level option is enough until per-language
  # splits are wanted.
  config.runtimePkgs = with pkgs; [
    ripgrep
    fd
    lazygit
    lua-language-server
    stylua
    bash-language-server
    shellcheck
    vscode-langservers-extracted
  ];
}
