# Closure notes: docs/plugins.md
{ pkgs, custom }:
let
  # Three packages in this closure are flagged unfree in nixpkgs:
  #   scope.nvim               auto-generated metadata, licence undetermined
  #   copilot-language-server  Microsoft binary, pulled in by copilot-lualine
  #   harpoon-lualine          same undetermined-metadata case as scope.nvim
  # Accept exactly those rather than enabling allowUnfree globally.
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
  # ai.lua only turned off the tmux mux backend; the plugin itself is enabled and
  # blink's <Tab> chain calls sidekick's next-edit-suggestion directly.
  ai = {
    lazy = false;
    data = [ sidekick-nvim ];
  };

  # --- optional, activated by lze ------------------------------------------
  # Grammars are listed explicitly. withAllGrammars pulled 320 parsers (251 MB),
  # almost all for languages this config never opens.
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
  # Declared explicitly rather than left as a transitive dependency of
  # copilot-lualine. copilot-lua supplies inline ghost text; blink-copilot
  # surfaces it as a completion source.
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
  # Both arrived via LazyVim extras (editor.harpoon2, editor.aerial), not from
  # the config's own specs. lualine's centre component needs harpoon-lualine.
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
      # yazi-nvim removed; the user disabled it and oil is the file manager.
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
      # vim-illuminate removed; superseded by snacks.words.
      # unimpaired-nvim removed; superseded by mini.bracketed.
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
      # nvim-dap-ui removed; superseded by nvim-dap-view.
    ];
  };

  # --- restored after the closure rewrite dropped them --------------------
  # These were in the old lazy-lock.json and had lze specs or LazyVim-extra
  # keymaps pointing at them, but the rewritten closure omitted their nix specs.
  # which-key was the visible one: its lze spec existed, the plugin did not.
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
