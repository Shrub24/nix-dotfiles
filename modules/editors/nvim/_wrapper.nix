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
  #
  # Everything the editor enables as an LSP server belongs here, not only in
  # modules/editors/lsp.nix: that one lands in the home profile, and the wrapper
  # APPENDS its runtimePkgs to PATH rather than replacing it. Launched with a
  # bare PATH (a GUI entry, a systemd unit, `env -i`) those binaries are absent
  # and every server silently fails to start. Verified: with PATH=/usr/bin:/bin
  # gopls, marksman, texlab, yaml-language-server and vtsls all reported
  # executable = 0 before this list was completed.
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
