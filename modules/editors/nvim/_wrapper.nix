{
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  config.binName = "nvim";
  config.settings.aliases = [ ];
  config.settings.dont_link = true;

  # The Lua tree beside this file; includes and runtimepath come from here.
  config.settings.config_directory = ./.;

  config.specs = import ./_plugins.nix {
    inherit pkgs;
    custom = import ./_custom.nix { inherit pkgs; };
  };
  # Wrapper + spec routing notes: docs/wrapper.md
  config.runtimePkgs = with pkgs; [
    # general editor tooling
    ripgrep
    fd
    lazygit
    # LSP servers — keep in step with vim.lsp.enable calls in lua/plugins/lsp.lua
    lua-language-server
    basedpyright
    ruff
    bash-language-server
    vscode-langservers-extracted # json, css, html + eslint servers
    vtsls
    yaml-language-server
    marksman
    texlab
    gopls
    typos-lsp
    ast-grep
    helm-ls
    nil
    taplo
    # formatters and linters driven by conform / nvim-lint
    stylua
    shellcheck
  ];
}
