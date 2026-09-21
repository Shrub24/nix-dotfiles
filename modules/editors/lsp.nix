_: {
  # Language servers, linters and formatters for the Neovim config
  # (~/.config/nvim). Everything here is currently provided by mason; LazyVim
  # resolves servers through `vim.fn.executable()`, so anything on PATH is picked
  # up with no nvim-side change, and mason's own copies keep winning for as long
  # as it stays enabled.
  #
  # Enable by adding "lsp" to hmAspects in modules/hosts/arch.nix.
  #
  # Already supplied elsewhere, so deliberately absent below:
  #   nil, taplo, yamlfmt   -> modules/flake/tooling.nix
  #   ast-grep              -> modules/dev-tools/languages.nix
  #   prettier              -> modules/dev-tools/cli.nix
  #   yamllint              -> modules/agents/pi.nix
  #
  # Attribute names verified against nixpkgs.
  flake.modules.homeManager.lsp =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Language servers ------------------------------------------------
        lua-language-server # lua
        basedpyright # python
        ruff # python lint + format
        bash-language-server # shell
        vtsls # ts / js
        vscode-langservers-extracted # json, css, html and eslint servers
        yaml-language-server # yaml
        marksman # markdown
        texlab # latex (lua/plugins/tex.lua)

        # Dockerfile / compose (lang.docker extra)
        dockerfile-language-server
        docker-compose-language-service

        # Only if the matching extra stays enabled
        gopls # go   -> lang.go
        rust-analyzer # rust -> lang.rust

        # Linters ---------------------------------------------------------
        eslint
        shellcheck
        markdownlint-cli2
        hadolint
        typos-lsp
        semgrep

        # Formatters ------------------------------------------------------
        stylua
        shfmt
        nixfmt
        markdown-toc
      ];
    };
}
