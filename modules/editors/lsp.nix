_: {
  # Deliberately absent, supplied elsewhere: nil/taplo/yamlfmt (flake/tooling),
  # ast-grep (dev-tools), prettier (dev-tools/cli), yamllint (agents/pi).
  flake.modules.homeManager.lsp =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Language servers ------------------------------------------------
        lua-language-server
        basedpyright
        ruff
        bash-language-server
        vtsls
        vscode-langservers-extracted # json, css, html and eslint servers
        yaml-language-server
        marksman
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

        # Formatters ------------------------------------------------------
        stylua
        shfmt
        nixfmt
        markdown-toc
      ];
    };
}
