# Closure notes: docs/plugins.md
{ pkgs, custom }:
let
  # Narrow unfree allowlist: scope.nvim and harpoon-lualine have undetermined
  # licences; copilot-language-server is Microsoft's, via copilot-lualine.
  unfreeAllowed = [
    "scope.nvim"
    "copilot-language-server"
    "harpoon-lualine"
  ];
  pkgs' = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfreePredicate = p: builtins.elem (pkgs.lib.getName p) unfreeAllowed;
  };
in
with pkgs'.vimPlugins;
{
  # --- startup -------------------------------------------------------------
  lze = {
    lazy = false;
    data = [ lze ];
  };
  lzextras = {
    lazy = false;
    data = [ lzextras ];
  };
  plenary = {
    lazy = false;
    data = [ plenary-nvim ];
  };
  # Closure notes: docs/plugins.md
  core = {
    lazy = false;
    data = [
      snacks-nvim
      nvim-lspconfig
      conform-nvim
      scope-nvim
      smart-splits-nvim
      resession-nvim
      custom.pick-resession-nvim
    ];
  };
  # colors/noctalia.lua delegates syntax/LSP/treesitter/Diff groups to this, and
  # sets the colourscheme during startup, so it cannot be optional.
  theme = {
    lazy = false;
    data = [ base16-nvim ];
  };
  # ai.lua disables only sidekick's tmux backend; blink's <Tab> chain calls
  # next-edit-suggestion, so the plugin is startup.
  ai = {
    lazy = false;
    data = [ sidekick-nvim ];
  };

  # --- optional, activated by lze ------------------------------------------
  # Grammars listed explicitly: withAllGrammars pulls 320 parsers (251 MB), most
  # for languages this config never opens.
  treesitter = {
    lazy = true;
    data = [
      (nvim-treesitter.withPlugins (
        p: with p; [
          # treesitter plumbing + the config's own filetypes
          lua
          luadoc
          query
          vim
          vimdoc
          regex
          comment
          diff

          # from the enabled lang.* extras
          bash
          dockerfile
          gitattributes
          gitcommit
          gitignore
          git_rebase
          go
          gomod
          gosum
          gotmpl
          gowork
          helm
          java
          json
          json5
          markdown
          markdown_inline
          nix
          python
          r
          rust
          sql
          latex
          bibtex
          toml
          yaml

          # web + general source
          css
          html
          javascript
          tsx
          typescript

          # the config's own ftplugins
          matlab
          agda
          c
          cpp
          cmake
          make
        ]
      ))
      nvim-treesitter-textobjects
    ];
  };
  blink = {
    lazy = true;
    data = [
      blink-cmp
      # blink's `snippets` source reads the native vim.snippet collection.
      friendly-snippets
    ];
  };
  # Explicit, not transitive via copilot-lualine: copilot-lua supplies the ghost
  # text, blink-copilot surfaces it as a blink completion source.
  copilot = {
    lazy = true;
    data = [
      copilot-lua
      blink-copilot
    ];
  };
  blink-sources = {
    lazy = true;
    data = [
      blink-cmp-git
      blink-nerdfont-nvim
      blink-ripgrep-nvim
      colorful-menu-nvim
      lspkind-nvim
    ];
  };
  ui = {
    lazy = true;
    data = [
      lualine-nvim
      bufferline-nvim
      nvim-web-devicons
      nui-nvim
      copilot-lualine
    ];
  };
  editing = {
    lazy = true;
    data = [ inc-rename-nvim ];
  };
  navigation = {
    lazy = true;
    data = [
      dropbar-nvim
      nvim-ufo
      nvim-hlslens
      marks-nvim
    ];
  };
  # lualine's centre component needs harpoon-lualine.
  navigation-extras = {
    lazy = true;
    data = [
      harpoon2
      harpoon-lualine
      aerial-nvim
    ];
  };
  files = {
    lazy = true;
    data = [
      oil-nvim
    ];
  };
  # mini.nvim is a monorepo: ai, bracketed, hipatterns, icons, move, pairs,
  # surround all come from this one attr.
  mini = {
    lazy = true;
    data = [ mini-nvim ];
  };
  git = {
    lazy = true;
    data = [
      gitsigns-nvim
      diffview-plus-nvim
      octo-nvim
    ];
  };
  appearance = {
    lazy = true;
    data = [
      rainbow-delimiters-nvim
      # snacks.words supersedes vim-illuminate, mini.bracketed supersedes
      # unimpaired-nvim.
    ];
  };
  custom-plugins = {
    lazy = true;
    data = [ custom.herdr-nvim ];
  };

  # --- filetype-scoped -----------------------------------------------------
  repl = {
    lazy = true;
    data = [
      vim-slime
      custom.vim-slime-cells
    ];
  };
  languages = {
    lazy = true;
    data = [
      vimtex
      cornelis
      haskell-vim
    ];
  };

  # --- key/command-triggered ----------------------------------------------
  dap = {
    lazy = true;
    data = [
      nvim-dap-view
    ];
  };

  # --- plugins referenced by lze specs in the Lua tree --------------------
  # Dropping one leaves a spec with no plugin behind it.
  keys = {
    lazy = true;
    data = [
      which-key-nvim
      flash-nvim
      dial-nvim
      yanky-nvim
    ];
  };
  search = {
    lazy = true;
    data = [
      grug-far-nvim
      trouble-nvim
      nvim-lint
    ];
  };
  misc = {
    lazy = true;
    data = [
      todo-comments-nvim
      nvim-ts-autotag
      nvim-treesitter-context
    ];
  };
  ui-extra = {
    lazy = true;
    data = [
      noice-nvim
      render-markdown-nvim
      litee-nvim
      SchemaStore-nvim
      ts-comments-nvim
      vim-startuptime
    ];
  };
  lang-extra = {
    lazy = true;
    data = [
      crates-nvim
      lazydev-nvim
      venv-selector-nvim
      rustaceanvim
      nvim-jdtls
      helm-ls-nvim
      kulala-nvim
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
    ];
  };
  test = {
    lazy = true;
    data = [
      neotest
      neotest-golang
      neotest-python
      neotest-testthat
      nvim-dap-go
      nvim-dap-python
      nvim-dap-virtual-text
    ];
  };
}
# Closure notes: docs/plugins.md
