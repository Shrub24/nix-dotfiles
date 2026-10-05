-- Symbol outline. lualine's `extensions` list names it; inert until the plugin
-- exists.
return {
  {
    "aerial.nvim",
    auto_enable = true,
    cmd = { "AerialToggle", "AerialOpen", "AerialOpenAll", "AerialNavToggle" },
    after = function()
      require("aerial").setup({})
    end,
  },
}
