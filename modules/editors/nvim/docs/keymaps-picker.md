# keymaps-picker.lua provenance

Moved from `lua/config/keymaps-picker.lua` so the code stays lean. Comments in code are signposts only.

```
LazyVim's editor.snacks_picker extra (keymaps only), ported verbatim from
lazyvim/plugins/extras/editor/snacks_picker.lua. The extra was enabled in the
old config, so its bindings are muscle memory, not additions. Trim from here
later; do not "improve" any map.

Every LazyVim.* call in the source is replaced:
LazyVim.pick("files")        -> Snacks.picker.files()
LazyVim.pick("oldfiles")     -> Snacks.picker.recent()
LazyVim.pick.config_files()  -> Snacks.picker.config_files()
LazyVim.pick("grep")         -> Snacks.picker.grep()   (live_grep -> grep)
LazyVim.pick("grep_word")    -> Snacks.picker.grep_word()
LazyVim.config.kind_filter   -> dropped (lsp_symbols lists all kinds)
LazyVim.root()               -> vim.fs.root() + vim.uv.cwd() (picker toggle_cwd)

Dropped maps:
<leader>sp  Snacks.picker.lazy()  no lazy.nvim to search
<a-s>, s    flash inside the picker (input keys, not a leader map)

Ported elsewhere:
gd gr gI gy <leader>ss <leader>sS gai gao -> lua/config/lsp.lua (buffer-local
on LspAttach, with the extra's `has` capability gates)
<leader>st <leader>sT -> lua/plugins/lazyvim-core.lua, on the todo-comments spec
keys: Snacks.picker.todo_comments is registered by todo-comments.nvim itself,
so the map must be able to load that plugin
<leader>fc  the extra's Snacks.picker.config_files() does not exist; the
LazyVim function it wrapped is Snacks.picker.files({ cwd = stdpath("config") })
<a-c> toggle_cwd             -> lua/plugins/snacks.lua (picker setup)

Requires snacks (startup set).
```
