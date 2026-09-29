# LSP behaviour layer

Moved from `lua/config/lsp.lua` so the code stays lean. Comments in code are signposts only.

```
LazyVim's LSP behaviour layer, ported from
lua/lazyvim/plugins/lsp/init.lua and lua/lazyvim/util/lsp.lua.

Every LazyVim.* call got a plain-vim replacement:
LazyVim.lsp.action[kind]           -> code_action(kind)
LazyVim.lsp.code_actions()         -> code_actions()
LazyVim.set_default()              -> set_default() (only while the option is at its default)
Snacks.util.lsp.on()               -> LspAttach autocmd + client:supports_method()
lazyvim.plugins.lsp.keymaps.set()  -> apply_keys(); Neovim has no handler for the
`keys` field of vim.lsp.config, so the maps are
set buffer-locally on attach with the same gating

Needs snacks (startup set): picker for <leader>cl, rename for <leader>cR, words for
the ]] / [[ and <a-n> / <a-p> reference jumps.
```
