-- Ported from lua/plugins/dap.lua. nvim-dap itself is a nix dependency of
-- nvim-dap-view; its `<leader>de` keymap lives in init.lua's inline nvim-dap
-- spec, so it is only created once dap is loaded.
return {
  {
    "nvim-dap-view",
    auto_enable = true,
    keys = {
      {
        "<leader>dv",
        "<cmd>DapViewToggle<cr>",
        desc = "Toggle Dap View",
      },
    },
    after = function()
      -- Ported verbatim, including the type annotations.
      ---@module 'dap-view'
      ---@type dapview.Config
      local opts = {
        auto_toggle = true,
        winbar = {
          controls = {
            enabled = true,
          },
        },
      }
      require("dap-view").setup(opts)
    end,
  },
}
