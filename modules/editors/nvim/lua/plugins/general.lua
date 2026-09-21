-- Ported from lua/plugins/general.lua.
--
-- Changes, none of them behavioural:
--   treesitter: `build = ":TSUpdate"` is gone — grammars come from nix
--   (`withPlugins` in _plugins.nix), so there is nothing to update. The
--   `opts.disable` list is preserved as a filetype disable table for parity.
--   `dependencies` fields are gone; each dependency is its own nix spec.
--
-- Not carried over (source had them commented out): neoscroll, venv-selector,
-- remote-nvim, satellite.
return {
  {
    "smart-splits.nvim",
    auto_enable = true,
    lazy = false,
    after = function()
      require("smart-splits").setup({
        multiplexer_integration = "herdr",
      })
    end,
  },
  {
    "nvim-treesitter",
    auto_enable = true,
    lazy = false,
    after = function()
      -- Ported from the source `opts.disable` list; grammars themselves are
      -- nix-managed.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "latex", "text", "opencode", "opencode-output", "fstab", "kdl" },
        callback = function(args)
          pcall(function()
            vim.treesitter.stop(args.buf)
          end)
        end,
      })
      vim.treesitter.language.register("bash", "sh")
    end,
  },
  {
    "nvim-treesitter-textobjects",
    auto_enable = true,
    lazy = false,
  },
  {
    "dropbar.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("dropbar").setup({
        bar = {
          enable = function(buf, win, _)
            buf = vim._resolve_bufnr(buf)
            if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
              return false
            end

            if
              not vim.api.nvim_buf_is_valid(buf)
              or not vim.api.nvim_win_is_valid(win)
              or vim.fn.win_gettype(win) ~= ""
              or vim.wo[win].winbar ~= ""
              or vim.bo[buf].ft == "help"
              or vim.bo[buf].ft == "matlab"
            then
              return false
            end

            local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
            if stat and stat.size > 1024 * 1024 then
              return false
            end

            return vim.bo[buf].ft == "markdown"
              or pcall(vim.treesitter.get_parser, buf)
              or not vim.tbl_isempty(vim.lsp.get_clients({
                bufnr = buf,
                method = "textDocument/documentSymbol",
              }))
          end,
        },
      })
    end,
  },
  {
    "octo.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("octo").setup({
        picker = "snacks",
      })
    end,
  },
  {
    -- Single module of the mini.nvim monorepo already used for mini.ai /
    -- mini.pairs / mini.icons. Mappings kept as nvim-surround's so muscle
    -- memory carries over; visual mode is `sa` rather than nvim-surround's `S`.
    "mini.surround",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("mini.surround").setup({
        mappings = {
          add = "ys",
          delete = "ds",
          replace = "cs",
          find = "gs",
          find_left = "gS",
          highlight = "",
          update_n_lines = "",
        },
      })
    end,
  },
  {
    -- Broader ]/[ set than unimpaired; LazyVim already owns most prefixes, so
    -- only the groups it does not bind are enabled. Defaults: no `h` group, so
    -- git.lua's ]h / [h (gitsigns hunks) are untouched.
    "mini.bracketed",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("mini.bracketed").setup({})
    end,
  },
  {
    "nvim-hlslens",
    auto_enable = true,
    keys = {
      {
        "n",
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        desc = "Next Search Result",
      },
      {
        "N",
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        desc = "Prev Search Result",
      },
      {
        "*",
        [[*<Cmd>lua require('hlslens').start()<CR>]],
        desc = "Search Word Forward",
      },
      {
        "#",
        [[#<Cmd>lua require('hlslens').start()<CR>]],
        desc = "Search Word Backward",
      },
      {
        "g*",
        [[g*<Cmd>lua require('hlslens').start()<CR>]],
        desc = "Search Word Forward (Fuzzy)",
      },
      {
        "g#",
        [[g#<Cmd>lua require('hlslens').start()<CR>]],
        desc = "Search Word Backward (Fuzzy)",
      },
      {
        "<leader>L",
        "<cmd>nohlsearch<cr>",
        desc = "Clear Highlights",
      },
    },
    after = function()
      require("hlslens").setup()
    end,
  },
  {
    "marks.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("marks").setup({
        default_mappings = true,
      })
    end,
  },
  {
    "nvim-ufo",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("ufo").setup()
    end,
  },
}
