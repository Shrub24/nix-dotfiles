# Plugin closure

Moved from `modules/editors/nvim/_plugins.nix` so the code stays lean. Comments in code are signposts only.

```
Plugin closure for the neovim wrapper, ported from the old LazyVim config.

Nix decides what exists and whether a plugin is startup or optional; the Lua
tree decides when and how it loads. A group is a spec:

{ lazy = false; data = [ ... ]; }  -> pack/myNeovimPackages/start
{ lazy = true;  data = [ ... ]; }  -> pack/myNeovimPackages/opt

`lazy` is what routes a group between start and opt (normalize.nix partitions
on it, defaulting to false), so an optional group MUST say lazy = true.

Loading triggers were read off the old specs, not guessed:
lazy = false   -> startup (was `lazy = false`)
DeferredUIEnter -> UI-ish, after first screen (was `event = "VeryLazy"`)
ft / keys / event -> the same trigger lze uses
```

```
The old specs set `lazy = false` on these.
refactoring.nvim is deliberately NOT here. It was declared but never used
(no :Refactor maps, no calls anywhere in the config), and it was the only
reason async.nvim was installed — which broke nvim-ufo:

refactoring-nvim  -> async.nvim      lua/async.lua = a TABLE
nvim-ufo          -> promise-async   lua/async.lua = a FUNCTION

Both ship the same module path, async.nvim sorts first in start/, so
require('async') handed nvim-ufo a table:
attempt to call upvalue 'async' (a table value)  (ufo/fold/init.lua:35)

Dropping refactoring.nvim removes async.nvim with it, and promise-async's
async.lua becomes the only one on the rtp. No shim needed.
```

```
Genuinely parked in the old config with plugin-level `enabled = false`
(appearance.lua:11/61, disabled.lua:4/8, files.lua:26). Not installed here.
rasulomaroff/reactive.nvim
sphamba/smear-cursor.nvim
folke/persistence.nvim    — superseded by resession
rcarriga/nvim-dap-ui      — superseded by nvim-dap-view
mikavilpas/yazi.nvim      — oil is the file manager
Never in the closure, from LazyVim extras rather than this config:
nvim-telescope/telescope.nvim, karb94/neoscroll.nvim, lewis6991/satellite.nvim,
amitds1997/remote-nvim.nvim
```
