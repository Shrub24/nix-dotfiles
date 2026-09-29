# LazyVim core options

Moved from `lua/config/options-lazyvim.lua` so the code stays lean. Comments in code are signposts only.

```
LazyVim's core editor options, ported.

These lived in LazyVim itself (`lua/lazyvim/config/options.lua`) and were
never part of this config's own options.lua — so dropping LazyVim silently
removed them. The most visible one was `confirm`, which is why :qa stopped
responding on a session with any modified buffer: without it the refusal is
a message rather than a prompt.

Loaded before config.options, so this config's own settings win.

Three substitutions from the original:
* formatexpr  pointed at LazyVim.format.formatexpr(); conform owns
formatting here, so it is left at the neovim default.
* statuscolumn pointed at LazyVim.statuscolumn(); snacks.statuscolumn is
enabled in lua/plugins/snacks.lua and sets its own.
* the LazyVim.terminal.setup("pwsh") line was already commented out.
This file is automatically loaded by plugins.core
```

```
Optionally setup the terminal to use
This sets `vim.o.shell` and does some additional configuration for:
* pwsh
* powershell
LazyVim.terminal.setup("pwsh")

Set LSP servers to be ignored when used with `util.root.detectors.lsp`
for detecting the LSP root
```
