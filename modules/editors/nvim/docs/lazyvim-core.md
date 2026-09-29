# lazyvim-core

Moved from `lua/plugins/lazyvim-core.lua`.

```
LazyVim.mini.ai(opts), inlined, with LazyVim.mini.ai_buffer replaced
by its one-line body. Both this spec and the inline one in init.lua
target mini.nvim; this file is required first in init.lua's groups
list, and the inline spec's bare mini.ai.setup() after it would
override these textobjects -- so init.lua's inline mini spec is
reduced to icons + mock only (done there).
```

---

```
LazyVim core plugin configuration, ported from upstream LazyVim
(lua/lazyvim/plugins/{editor,ui,coding,treesitter,formatting}.lua and the
editor.dial / coding.yanky extras).

This config only ever OVERRODE LazyVim defaults; it never declared these
plugins. Every opts table below is upstream's, verbatim, except that:
LazyVim.root() / LazyVim.root.git() -> Snacks.git.get_root()
LazyVim.mini.pairs(opts)            -> inline (mini.pairs' own mappings check)
LazyVim.mini.ai_buffer              -> inline buffer textobject
LazyVim.mini.ai_whichkey            -> dropped (registers which-key labels
for custom textobjects; cosmetic)
LazyVim.on_load / on_very_lazy      -> lze after/dep_on
LazyVim.format.register             -> dropped (registering conform as the
LazyVim formatter is LazyVim-only)
LazyVim.cmp.actions.snippet         -> native vim.snippet expand/jump
lazy.nvim's LazyFile event          -> { "BufReadPost", "BufNewFile", "BufWritePre" }

Treesitter opts deliberately omit ensure_installed/indent/folds/highlight:
grammars are nix-managed (see _plugins.nix) and nvim-treesitter on the main
branch no longer uses those opts; the disable list was already ported as a
FileType autocmd in lua/plugins/general.lua, which takes precedence.

This file loads BEFORE the user's own groups (see init.lua), so anything in
lua/plugins/*.lua still overrides it.
```
