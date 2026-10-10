# Linting

`lua/plugins/linting.lua` ports LazyVim's `lua/lazyvim/plugins/linting.lua` — same `events`,
`linters_by_ft` and `linters` override table, same `_` fallback and `*` global linter handling,
same `condition` filtering. `LazyVim.warn` becomes `vim.notify`.

Two deviations: LazyVim's `LazyFile` trigger becomes `BufReadPre`/`BufNewFile` (matching the
gitsigns spec), and linter binaries come from `runtimePkgs` in `_wrapper.nix` rather than being
installed at runtime.
