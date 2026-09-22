# Plugin closure for the neovim wrapper, ported from the old LazyVim config.
#
# Nix decides what exists and whether a plugin is startup or optional; the Lua
# tree decides when and how it loads. A group is a spec:
#
#   { lazy = false; data = [ ... ]; }  -> pack/myNeovimPackages/start
#   { lazy = true;  data = [ ... ]; }  -> pack/myNeovimPackages/opt
#
# `lazy` is what routes a group between start and opt (normalize.nix partitions
# on it, defaulting to false), so an optional group MUST say lazy = true.
#
# Loading triggers were read off the old specs, not guessed:
#   lazy = false   -> startup (was `lazy = false`)
#   DeferredUIEnter -> UI-ish, after first screen (was `event = "VeryLazy"`)
#   ft / keys / event -> the same trigger lze uses
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
  # The old specs set `lazy = false` on these.
  # refactoring.nvim is deliberately NOT here. It was declared but never used
  # (no :Refactor maps, no calls anywhere in the config), and it was the only
  # reason async.nvim was installed — which broke nvim-ufo:
  #
  #   refactoring-nvim  -> async.nvim      lua/async.lua = a TABLE
  #   nvim-ufo          -> promise-async   lua/async.lua = a FUNCTION
  #
  # Both ship the same module path, async.nvim sorts first in start/, so
  # require('async') handed nvim-ufo a table:
  #   attempt to call upvalue 'async' (a table value)  (ufo/fold/init.lua:35)
  #
  # Dropping refactoring.nvim removes async.nvim with it, and promise-async's
  # async.lua becomes the only one on the rtp. No shim needed.
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

# Genuinely parked in the old config with plugin-level `enabled = false`
# (appearance.lua:11/61, disabled.lua:4/8, files.lua:26). Not installed here.
#   rasulomaroff/reactive.nvim
#   sphamba/smear-cursor.nvim
#   folke/persistence.nvim    — superseded by resession
#   rcarriga/nvim-dap-ui      — superseded by nvim-dap-view
#   mikavilpas/yazi.nvim      — oil is the file manager
# Never in the closure, from LazyVim extras rather than this config:
#   nvim-telescope/telescope.nvim, karb94/neoscroll.nvim, lewis6991/satellite.nvim,
#   amitds1997/remote-nvim.nvim
