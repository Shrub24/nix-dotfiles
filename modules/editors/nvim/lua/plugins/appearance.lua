return {
  {
    -- Beyond mini.hipatterns' #rrggbb: alpha hex, rgb(), hsl(), named colours, var().
    "nvim-highlight-colors",
    event = "DeferredUIEnter",
    after = function()
      require("nvim-highlight-colors").setup()
    end,
  },
  {
    "rainbow-delimiters.nvim",
    auto_enable = true,
  },
}
