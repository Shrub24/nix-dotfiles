-- Ported from lua/plugins/appearance.lua.
--
-- Dropped during the port:
--   base16-nvim spec  — startup set in _plugins.nix (`theme`); the colourscheme
--                       is applied at the end of init.lua
--   LazyVim spec      — LazyVim is no longer infrastructure; colors/noctalia.lua
--                       sets the colourscheme
--   reactive.nvim, smear-cursor.nvim — plugin-level `enabled = false` in the
--                       source, so they were never loaded
return {
  {
    "rainbow-delimiters.nvim",
    auto_enable = true,
  },
}
