-- Ported from lua/plugins/lsp.lua. LazyVim resolved LSP servers from PATH and
-- started those listed under opts.servers; without LazyVim, `vim.lsp.enable`
-- does that job. basedpyright and ruff were enabled in the source; lua_ls and
-- bashls were enabled implicitly by LazyVim's core. The servers below them were
-- enabled by LazyVim's lang.*/linting extras and are back after a
-- `vim.fn.executable()` check on each lspconfig `cmd`.
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
      -- lang.json / lang.yaml / lang.markdown / lang.tex / lang.go / lang.helm
      -- / linting.eslint, plus the servers mason had installed.
      vim.lsp.enable "jsonls"
      vim.lsp.enable "yamlls"
      vim.lsp.enable "marksman"
      vim.lsp.enable "texlab"
      vim.lsp.enable "gopls"
      vim.lsp.enable "helm_ls"
      vim.lsp.enable "eslint"
      vim.lsp.enable "ast_grep"
      vim.lsp.enable "vtsls"
      vim.lsp.enable "typos_lsp"
      -- NOT enabled: lspconfig's `just` server starts `just-lsp`, which is not
      -- on PATH (`vim.fn.executable("just-lsp") == 0`). Add the package and
      -- `vim.lsp.enable "just"` here once it is.
      -- sidekick's next-edit-suggestions run on the copilot LSP server,
      -- not on copilot.lua (which only does completions).
      vim.lsp.enable "copilot"
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
