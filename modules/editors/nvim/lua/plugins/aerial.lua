-- Aerial (symbol outline). Came from LazyVim's editor.aerial extra; nothing in
-- the old config configured it. lualine's `extensions` list names it, which is
-- inert until the plugin exists.
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
