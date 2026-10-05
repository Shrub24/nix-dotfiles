-- Reproduces the setup from LazyVim's editor.harpoon2 extra.
return {
  {
    "harpoon",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("harpoon"):setup({
        settings = { save_on_toggle = true },
      })
    end,
  },
  {
    -- lualine's centre component: a component, not a plugin, so no setup().
    "harpoon-lualine",
    auto_enable = true,
    event = "DeferredUIEnter",
  },
}
