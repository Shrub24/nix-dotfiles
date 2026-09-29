# keymaps-core.lua provenance

Moved from `lua/config/keymaps-core.lua` so the code stays lean. Comments in code are signposts only.

```
LazyVim's core keymaps, ported verbatim from
lazyvim/config/keymaps.lua so muscle memory carries over. The user trims
from here later; do not "improve" any map.

Every LazyVim.* call in the source is replaced:
safe_keymap_set            -> vim.keymap.set (no lazy.nvim keys handler)
LazyVim.root()/root.git()  -> Snacks.git.get_root()
LazyVim.cmp.actions.snippet_stop -> dropped (blink.cmp is the engine; no
lazy.nvim snippet state to stop)
LazyVim.format.snacks_toggle     -> inline autoformat g/b-variable toggle
LazyVim.news.changelog     -> map dropped (LazyVim does not exist)

Requires snacks (startup set): bufdelete, toggle, picker, git, terminal.
```
