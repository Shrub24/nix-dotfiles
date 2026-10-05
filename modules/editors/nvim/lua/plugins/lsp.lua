-- Servers LazyVim's core and lang.*/linting extras used to enable; `vim.lsp.enable`
-- does that job now, gated on `vim.fn.executable()` where the server is optional.
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
      -- from LazyVim's lang.json/yaml/markdown/tex/go/helm and linting.eslint extras.
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
      -- `just` is absent: lspconfig's server needs `just-lsp` on PATH. Enable it
      -- here once the package is added.
      -- sidekick's next-edit-suggestions run on the copilot LSP server, not on
      -- copilot.lua, which only does completions.
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
