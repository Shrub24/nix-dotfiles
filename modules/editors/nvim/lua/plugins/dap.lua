-- nvim-dap arrives as a nix dependency of nvim-dap-view; its `<leader>de` keymap
-- lives in init.lua's inline nvim-dap spec, so it only exists once dap loads.
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
