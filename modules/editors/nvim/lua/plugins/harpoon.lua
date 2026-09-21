-- Harpoon. Came from LazyVim's editor.harpoon2 extra, so there is no source
-- spec in the old config to port from. The extra's setup is reproduced here;
-- the <leader>1..9 / <leader>ha maps are part of the _keymap-parity.md backlog.
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
    -- lualine's centre component. A component, not a plugin: no setup().
    "harpoon-lualine",
    auto_enable = true,
    event = "DeferredUIEnter",
  },
}
