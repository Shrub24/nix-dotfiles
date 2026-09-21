-- Ported from lua/plugins/files.lua. yazi.nvim had plugin-level
-- `enabled = false` in the source, so its spec is not carried over.
return {
  {
    "oil.nvim",
    auto_enable = true,
    keys = {
      {
        "<leader>W",
        function()
          require("oil").open(nil, { preview = {} })
        end,
        desc = "Open Oil",
      },
    },
    after = function()
      require("oil").setup({
        watch_for_changes = true,
        keymaps = {
          ["H"] = { "actions.toggle_hidden", mode = "n" },
        },
        view_options = {
          show_hidden = true,
        },
      })
    end,
  },
}
