-- Ported from lua/plugins/lsp.lua. LazyVim resolved LSP servers from PATH and
-- started those listed under opts.servers; without LazyVim, `vim.lsp.enable`
-- does that job. basedpyright and ruff were enabled in the source; lua_ls and
-- bashls were enabled implicitly by LazyVim's core.
--
-- refactoring.nvim was dropped here: it was declared but never used (the config
-- maps no `:Refactor` keys, and LazyVim's editor.refactoring extra supplied
-- none either), and it was the only thing pulling in async.nvim — whose
-- lua/async.lua is a *table* at the same module path where promise-async ships
-- a *function*, which broke nvim-ufo. See the note in _plugins.nix.
return {
  {
    "nvim-lspconfig",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      vim.lsp.enable "basedpyright"
      vim.lsp.enable "ruff"
      vim.lsp.enable "lua_ls"
      vim.lsp.enable "bashls"
    end,
  },
  {
    "conform.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "x" },
        desc = "Format Injected Langs",
      },
    },
    after = function()
      require("conform").setup({
        formatters_by_ft = {
          yaml = { "yamlfmt" },
          python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
        },
      })
    end,
  },
}
