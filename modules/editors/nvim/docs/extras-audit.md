# LazyVim extras + core-table audit (nix nvim config)

Scope: what each of the 35 LazyVim extras enabled in the old editor supplied, what the new
nix config actually delivers today, and which LazyVim core tables (`formatting.lua`,
`linting.lua`, LSP behaviour layer, treesitter, mini.*) the extras extend. Functional gaps
only; cosmetic differences are marked and left.

## 0 Snapshot, method, evidence grades

| Ref                   | What it is                                                                                                                                                                                                             |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tree**              | `/home/saurabhj/.dotfiles/nix/modules/editors/nvim` at 2026-10-09 (owner-declared frozen)                                                                                                                              |
| **Current build**     | `/nix/store/l6nlappmb46jasgv326dzxsh2hbmbifv-neovim-unwrapped-0.12.5/bin/nvim`, config `/nix/store/9bkcn287snav9cpxlgjxlvi05dh5vqbl-nvim` — `diff -rq` against the tree is clean, so it is the frozen tree exactly [R] |
| **Installed profile** | superseded: `…-home-manager-path/bin/nvim` → `/nix/store/xzil2s7yz2d5rx89cxzzqdfd4sfnpqj6-neovim-unwrapped-0.12.5`, config `/nix/store/ynj9l9yshq3mfsckqm1l4njc3rkpjs7z-nvim` (predates the tree; not switched yet)    |
| **Old LazyVim**       | `/tmp/lazyvim/LazyVim-999700997f72227187d49d8b92667183dc7fc809`                                                                                                                                                        |
| **Old extras**        | `/home/saurabhj/.config/nvim/lazyvim.json` (35 entries), `lazy-lock.json`                                                                                                                                              |
| **Old config**        | `/home/saurabhj/.config/nvim/lua/**` (own overrides); the old editor's live `nvim_get_keymap` capture is `_keymap-parity.md` in the tree                                                                               |

Grades used below: **[S]** read from source · **[R]** reproduced at runtime on the **current
build** (every runtime claim, unless it says _historical_) · **[D]** document claim no longer
re-verifiable · **[U]** unknown.

All probes run headless with `XDG_{CONFIG,DATA,STATE,CACHE}_HOME` redirected to `/tmp/probe`,
so no user state is touched. Keymap inventory, conform/lint/server/binaries/grammar probes and
the two keypress-failure probes were re-run on the current build; the isolated pre-fix results
from the installed profile agree on every extras-related point and are not repeated.

Reusable probe artifacts: `/tmp/probe/main{2,4,6}.lua` (event-fired feature, command/module and
markdown/lint probes), `/tmp/probe/maps-current.txt` (full 473-map dump, leader resolved),
`/tmp/probe/report{2,4,6}-current.txt`. Run them as
`env XDG_CONFIG_HOME=/tmp/probe/xdg/config XDG_DATA_HOME=… XDG_STATE_HOME=… XDG_CACHE_HOME=…
<current-build>/bin/nvim --headless -c 'luafile /tmp/probe/main2.lua'`.

**Installed profile → current build delta** (`diff -rq`, `diff -uw`, [S]):

```
init.lua                  group list (+plugins.linting, +plugins.markdown)
lua/plugins/lsp.lua       markdown / markdown.mdx formatter rows + their two conditions
lua/plugins/linting.lua   new
lua/plugins/markdown.lua  new
_wrapper.nix              runtimePkgs += yamlfmt, prettierd, prettier, markdownlint-cli2, markdown-toc
```

`_plugins.nix` and the rest of the tree differ only in indentation (tabs); the closure plugin
list is unchanged, so the “declared but unspecced” analysis is identical for both builds.
Anything the installed profile lacked (`nvim-lint`, `markdown-preview.nvim`,
`render-markdown.nvim`, the two markdown formatter rows, five formatter binaries) exists and
was probed on the current build.

The old LazyVim checkout and the old mason package tree are both gone; old-editor claims come
from the fetched LazyVim tarball, `lazyvim.json`, `lazy-lock.json` and the surviving
`~/.config/nvim/lua` tree.

## 1 What the old editor actually had

The 35 entries in `lazyvim.json`, all enabled (i.e. every one contributed live behaviour):

```
ai.copilot  ai.sidekick  coding.yanky  dap.core  editor.aerial  editor.dial
editor.harpoon2  editor.inc-rename  editor.mini-move  editor.refactoring
editor.snacks_picker  formatting.prettier  lang.docker  lang.git  lang.go  lang.helm
lang.java  lang.json  lang.markdown  lang.nix  lang.python  lang.r  lang.rust  lang.sql
lang.tex  lang.toml  lang.yaml  linting.eslint  test.core  ui.treesitter-context
util.dot  util.mini-hipatterns  util.octo  util.rest  util.startuptime
```

Core behaviour those extras extend, for reference:

- **`plugins/formatting.lua:67-94`** — `default_format_opts = { timeout_ms = 3000, async = false,
quiet = false, lsp_format = "fallback" }`; core `formatters_by_ft = { lua = stylua,
fish = fish_indent, sh = shfmt }` (`:73-77`); an `injected` formatter override; `<leader>cF`; and
  `LazyVim.format.register(conform, priority 100, primary)` + format-on-save driven by
  `vim.g.autoformat` (`util/format.lua:53-131`).
- **`plugins/linting.lua`** — nvim-lint on `{ BufWritePost, BufReadPost, InsertLeave }` with
  debounce, `linters_by_ft = { fish = { fish } }`, the `_` fallback and `*` global linter
  handling, and a `linters` override table with `condition`.
- **`plugins/lsp/init.lua` + `util/lsp.lua`** — LspAttach key set, diagnostics config,
  `<leader>cl` (Lsp Info), `<leader>cm` (Mason), codelens actions, inlay hints.
- **`config/keymaps.lua`** — core toggles: `<leader>us` spell, `<leader>uT` treesitter,
  `<leader>uZ`/`<leader>uz` zoom/zen, `<leader>qq` quit all, etc.
- **`plugins/ui.lua:8-11`** — bufferline group maps `<leader>bp`, `<leader>bP`, `<leader>br`,
  `<leader>bl`.
- **`plugins/editor.lua:5-25`** — grug-far `<leader>sr` / `:GrugFar`.

## 2 Extras inventory

State: ✅ ported · ◐ partial · ✗ missing · ⊘ dropped by decision.

| #   | Extra                   | LazyVim source                                                    | Supplies                                                                                                               | State now | Evidence                                                                                                                                                                                                                                                                                                                                                                                               |
| --- | ----------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `ai.copilot`            | `ai/copilot.lua:5,30,41,55,109`                                   | copilot.lua (ghost text only when `!ai_cmp`), copilot LSP, blink provider, lualine component                           | ◐         | copilot spec `init.lua:129-145`, blink provider `init.lua:203-209`, `copilot` in the enable list with `copilot-language-server` on the wrapper PATH [R]; **lualine `{ "copilot" }` (`lualine.lua:157`) cannot resolve** — copilot-lualine is in the closure (`_plugins.nix:156`) with no lze spec; current build: `lualine.components.copilot not found` + `lze.on_require: no plugin registered…` [R] |
| 2   | `ai.sidekick`           | `ai/sidekick.lua:6,18,59,133`                                     | copilot LSP ensure, lualine, NES cmp action, 10 maps (<leader>a group, `<c-.>`, `<leader>uN`), snacks send action      | ◐         | plugin is startup (`init.lua:86-97`), NES jump wired into blink `<Tab>` (`init.lua:251-255`); **all 10 maps absent** [R]                                                                                                                                                                                                                                                                               |
| 3   | `coding.yanky`          | `coding/yanky.lua:3,20`                                           | yanky plugin, opts, 8 maps                                                                                             | ◐         | maps present (`lazyvim-core.lua:327-368`) but **no `opts`/`after`, so `yanky.setup()` never runs**; **`<leader>p` calls `Snacks.picker.yanky_history()` (`:336`), which does not exist** — the registered source is `yanky` (`yanky.nvim/lua/yanky.lua:61-64`, inside `yanky.setup()`) and LazyVim calls `Snacks.picker.yanky()` (`coding/yanky.lua:20`); pressing it raises E5108 [R][S]              |
| 4   | `dap.core`              | `dap/core.lua:21,26,29,82,108`                                    | nvim-dap + 18 maps, dap-ui, dap-virtual-text, mason-nvim-dap, launch.json/signs config                                 | ✗         | only `<leader>de` remains (`init.lua:107-119`, matches the old config's own map, desc "Stop on exceptions"); dap-view replaces dap-ui by decision (`docs/plugins.md`); `nvim-dap-virtual-text` in closure (`_plugins.nix:302`) with no spec; **no adapter on PATH** (`codelldb`/`debugpy`/`dlv`/`lldb-dap` all 0) [R]                                                                                  |
| 5   | `editor.aerial`         | `editor/aerial.lua:4,51,60,78,102`                                | aerial opts + `<leader>cs` AerialToggle, trouble `cs` disabled                                                         | ◐         | plugin spec loads on cmd (`aerial.lua:5-14`) with `setup({})`; no extra opts; `<leader>cs` is Trouble symbols (desc "Symbols (Trouble)") vs old Aerial [R]                                                                                                                                                                                                                                             |
| 6   | `editor.dial`           | `editor/dial.lua:15`                                              | dial.nvim + augend groups + `vim.g.dials_by_ft` + 4 expr maps                                                          | ✗         | maps present (`lazyvim-core.lua:316-325`) but **no `opts`/`after` ⇒ `dial.setup()` never runs**; `vim.g.dials_by_ft = nil` [R], helper `lazyvim-core.lua:7` indexes it, `<C-a>` errors before reaching `require("dial.map")` [S]                                                                                                                                                                       |
| 7   | `editor.harpoon2`       | `editor/harpoon2.lua:2`                                           | harpoon + opts + 12 maps (`<leader>H`, `<leader>h`, `<leader>1-9`)                                                     | ✗         | plugin configured (`harpoon.lua:4-12`, lualine component `lualine.lua:135` works), **no keys** [R]                                                                                                                                                                                                                                                                                                     |
| 8   | `editor.inc-rename`     | `editor/inc-rename.lua:7,14,37`                                   | inc-rename + `<leader>cr` override + noice preset                                                                      | ◐         | spec `init.lua:99-106`; `<leader>rr` = `:IncRename ` (`keymaps.lua:26`), `<leader>cr` = plain `vim.lsp.buf.rename` (`config/lsp.lua:107`, buffer-local); no noice preset [R][S]                                                                                                                                                                                                                        |
| 9   | `editor.mini-move`      | `editor/mini-move.lua:3`                                          | mini.move + `<A-j/k/h/l>`                                                                                              | ✅        | `mini.move` setup (`lazyvim-core.lua:279`) + all four maps; current-build keymap dump has `<M-j/k/h/l>` (Neovim's Alt notation) in normal and visual mode [R]                                                                                                                                                                                                                                          |
| 10  | `editor.refactoring`    | `editor/refactoring.lua:12`                                       | async.nvim + refactoring.nvim + 9 maps                                                                                 | ⊘         | dropped with a documented reason (async.nvim path clash broke nvim-ufo), `docs/plugins.md`                                                                                                                                                                                                                                                                                                             |
| 11  | `editor.snacks_picker`  | `editor/snacks_picker.lua:32,115,141,161,170,181,191,205,225,229` | pickers, dashboard, `<leader>uC`, flash input                                                                          | ✅        | 11/11 probed maps resolve; `<leader>sp` dropped (no lazy), `gd/gr/gI/gy/ss/sS` moved to `config/lsp.lua`, dashboard kept but `enabled = false` by a documented in-code decision (`snacks.lua`: sections are merged by index, so the default trailing `require("lazy.stats")` section cannot be dropped) [R][D]                                                                                         |
| 12  | `formatting.prettier`   | `formatting/prettier.lua:61,67,88`                                | prettier for 16 fts (14 + the 2 markdown ones) + conditions, prettierd                                                 | ◐         | only `markdown`/`markdown.mdx` rows use prettier (`lsp.lua:69-71`) [R]; **missing** `css graphql handlebars html javascript javascriptreact json jsonc less scss typescript typescriptreact vue` (yaml goes to `yamlfmt`) and the `has_parser`/`has_config` conditions + `vim.g.lazyvim_prettier_needs_config`; no `default_format_opts` [R][S]. Prettier/prettierd binaries are settled (owner)       |
| 13  | `lang.docker`           | `lang/docker.lua:16,24,34,43`                                     | dockerfile grammar, hadolint, `dockerls`, `docker_compose_language_service`                                            | ✗         | grammar present; **neither server enabled** [S] although both binaries are on the wrapper PATH [R]; no `dockerfile` linter row                                                                                                                                                                                                                                                                         |
| 14  | `lang.git`              | `lang/git.lua:7,12`                                               | 5 git grammars, cmp-git                                                                                                | ◐         | `gitattributes/gitcommit/gitignore/git_rebase` present, **`git_config` absent**; blink-cmp-git provider present (`init.lua:224-231`)                                                                                                                                                                                                                                                                   |
| 15  | `lang.go`               | `lang/go.lua:9,13,85,109,124,133,147`                             | go grammars, gopls settings, goimports+gofumpt, golangcilint, delve + nvim-dap-go, neotest-golang, mini.icons          | ✗         | `gopls` enabled with **no settings** (`lsp.lua:15`); no go formatter, no go linter, nvim-dap-go / neotest-golang unspecced, mini.icons filetypes absent [R][S]                                                                                                                                                                                                                                         |
| 16  | `lang.helm`             | `lang/helm.lua:12,17`                                             | helm grammar, helm-ls.nvim, `helm_ls`                                                                                  | ◐         | `helm_ls` enabled [S]; `helm-ls.nvim` in closure (`_plugins.nix:286`) with no spec                                                                                                                                                                                                                                                                                                                     |
| 17  | `lang.java`             | `lang/java.lua:35,41,59,68,84`                                    | java grammar, `configurations.java`, jdtls via nvim-jdtls with full opts + keys, java-debug-adapter/java-test, neotest | ✗         | `nvim-jdtls` in closure (`_plugins.nix:285`) with no spec; no `jdtls` binary [R]; `<leader>cx/cg/co/tt` all absent                                                                                                                                                                                                                                                                                     |
| 18  | `lang.json`             | `lang/json.lua:11,17,24`                                          | json5 grammar, SchemaStore.nvim, jsonls + schemas                                                                      | ◐         | `jsonls` enabled [R] without SchemaStore; `SchemaStore.nvim` in closure (`_plugins.nix:273`) with no spec ⇒ no JSON/YAML schema completion or validation                                                                                                                                                                                                                                               |
| 19  | `lang.markdown`         | `lang/markdown.lua:14,43,47,57,66,76,96`                          | mdx filetype, markdown formatters, markdownlint, marksman, markdown-preview, render-markdown                           | ✅        | measured on the current build: `lsp.lua:63-72` rows + the two formatter conditions, `linting.lua` markdown row, `marksman` enabled, and on a markdown buffer `render-markdown` loads with `<leader>um` = "Toggle Render Markdown", `<leader>cp` = "Markdown Preview", `:MarkdownPreview` exists [R]; missing only the `mdx` → `markdown.mdx` filetype mapping (`lang/markdown.lua:1-5`) [S]            |
| 20  | `lang.nix`              | `lang/nix.lua:7,11,19,28`                                         | nix grammar, **nil_ls**, nixfmt, statix                                                                                | ✗         | grammar present; **`nil_ls` not enabled** [S] although `nil` is on the wrapper PATH [R]; no `nix` formatter/linter rows                                                                                                                                                                                                                                                                                |
| 21  | `lang.python`           | `lang/python.lua:27,31,55,65,81,97,111,121`                       | ninja/rst grammars, ruff+pyright matrix, neotest-python, nvim-dap-python, venv-selector, cmp brackets                  | ◐         | `basedpyright` + `ruff` enabled [R]; `ninja`/`rst` grammars absent; **no server settings** — the old config's own `analysis.diagnosticMode = "workspace"` for basedpyright/ruff (`~/.config/nvim/lua/plugins/lsp.lua:8-25`) was not ported; venv-selector / nvim-dap-python / neotest-python unspecced, `<leader>cv` absent [R][S]                                                                     |
| 22  | `lang.r`                | `lang/r.lua:9,51,60,64,74,77`                                     | R.nvim (hook keys, pdfviewer), cmp-r, r/rnoweb grammars, `r_language_server`, neotest-testthat                         | ✗         | `R.nvim` not in the closure; `r` grammar present, `rnoweb` absent; no `r_language_server` and neither the `R` nor `r-languageserver` binary exists [R][S]; neotest-testthat in closure with no spec                                                                                                                                                                                                    |
| 23  | `lang.rust`             | `lang/rust.lua:21,40,46,58,130,142`                               | crates.nvim, rust/ron grammars, codelldb, rustaceanvim (rust-analyzer + bacon_ls disabled), neotest                    | ✗         | `rustaceanvim` + `crates.nvim` in closure (`_plugins.nix:284,281`) with no specs ⇒ **no Rust LSP** even though `rust-analyzer` is installed for this extra; `ron` grammar absent; no Cargo.toml client, no adapter [R]                                                                                                                                                                                 |
| 24  | `lang.sql`              | `lang/sql.lua:44,49,77,103,110,134,145,151,155,165`               | vim-dadbod trio, `<leader>D` DBUI, edgy panel, blink dadbod source, sqlfluff lint+format                               | ✗         | `vim-dadbod{,-ui,-completion}` in closure (`_plugins.nix:288-290`) with no spec ⇒ `:DB`/`:DBUI`/`<leader>D`/dadbod completion all unreachable [R]; sqlfluff not installed                                                                                                                                                                                                                              |
| 25  | `lang.tex`              | `lang/tex.lua:11,26,39`                                           | latex/bibtex grammars, vimtex (+`<localLeader>l`, `K`), texlab + `<Leader>K`                                           | ✗         | grammars present; **vimtex never loads** — its spec sits in `ftplugin/tex.lua`, which Neovim sources as an ftplugin and whose `return {…}` is discarded; runtime `:VimtexCompile` absent, `vim.g.vimtex_view_method = nil`, vimtex not on rtp [R][S]; `texlab` enabled without the override [R]                                                                                                        |
| 26  | `lang.toml`             | `lang/toml.lua:8`                                                 | `taplo`                                                                                                                | ✗         | `taplo` not enabled [S] although it is on the wrapper PATH [R]                                                                                                                                                                                                                                                                                                                                         |
| 27  | `lang.yaml`             | `lang/yaml.lua:10,17`                                             | SchemaStore.nvim, yamlls capabilities + settings + schemastore                                                         | ◐         | `yamlls` enabled [R] without schemastore or the `keyOrdering`/`format`/`validate` settings                                                                                                                                                                                                                                                                                                             |
| 28  | `linting.eslint`        | `linting/eslint.lua:10`                                           | eslint LSP with `workingDirectories.auto` + `format = auto_format`                                                     | ◐         | `eslint` enabled [S]; the `eslint` CLI resolves on PATH while `eslint_d` is missing [R]; no server settings, no eslint linter row for nvim-lint                                                                                                                                                                                                                                                        |
| 29  | `test.core`             | `test/core.lua:5,122`                                             | neotest + adapters + opts + 11 maps + `<leader>td`                                                                     | ✗         | `neotest`, `neotest-golang/python/testthat` in closure (`_plugins.nix:296-299`) with no spec; all `<leader>t*` maps absent [R]                                                                                                                                                                                                                                                                         |
| 30  | `ui.treesitter-context` | `ui/treesitter-context.lua:3`                                     | treesitter-context + `<leader>ut`                                                                                      | ✗         | plugin in closure (`_plugins.nix:263`) with no spec; `<leader>ut` absent [R]                                                                                                                                                                                                                                                                                                                           |
| 31  | `util.dot`              | `util/dot.lua:13,21,26`                                           | bashls + shellcheck, conditional grammars, `vim.filetype.add` patterns, `kitty`→bash                                   | ◐         | `bashls` enabled [S], shellcheck on the wrapper PATH [R], `bash` grammar + `register("bash","sh")` (`general.lua:27`); the `vim.filetype.add` block and conditional draws (`git_config`, `hyprlang`, `fish`, `rasi`) absent                                                                                                                                                                            |
| 32  | `util.mini-hipatterns`  | `util/mini-hipatterns.lua:7`                                      | mini.hipatterns: default + tailwind + shorthand highlighters                                                           | ◐         | `require("mini.hipatterns").setup({})` (`lazyvim-core.lua:280`) ⇒ default hex highlighter only; tailwind integration and the extra highlighters absent                                                                                                                                                                                                                                                 |
| 33  | `util.octo`             | `util/octo.lua:7,18,52`                                           | octo + opts + 6 maps + localleader groups + `@`/`#` insert maps + ExitPre                                              | ◐         | spec with `picker = "snacks"` (`general.lua:74-80`), **no keys**; `gi/gI/gp/gP` are Snacks gh pickers, `gS` is Snacks git_stash [R]; `<leader>gr` absent [R]; localleader groups, insert maps, ExitPre absent                                                                                                                                                                                          |
| 34  | `util.rest`             | `util/rest.lua:8,34`                                              | kulala.nvim + 14 `<leader>R*` maps, http/graphql grammars                                                              | ✗         | kulala in closure (`_plugins.nix:287`) with no spec; no `<leader>R*` [R]; http/graphql grammars absent                                                                                                                                                                                                                                                                                                 |
| 35  | `util.startuptime`      | `util/startuptime.lua:3`                                          | vim-startuptime + `:StartupTime`                                                                                       | ✗         | plugin in closure (`_plugins.nix:275`) with no spec                                                                                                                                                                                                                                                                                                                                                    |

### 2.1 Pattern behind most ✗ rows

The closure (`_plugins.nix`) is a superset of the lze specs. Plugins declared there with **no
spec anywhere in `lua/`** never load, so the only trace of their extra is the treesitter
grammar:

`vimtex`, `cornelis`, `nvim-jdtls`, `helm-ls.nvim`, `rustaceanvim`, `crates.nvim`,
`venv-selector.nvim`, `SchemaStore.nvim`, `lazydev.nvim`, `nvim-treesitter-context`,
`grug-far.nvim`, `vim-startuptime`, `kulala.nvim`, `vim-dadbod{,-ui,-completion}`,
`neotest{,-golang,-python,-testthat}`, `nvim-dap-go`, `nvim-dap-python`,
`nvim-dap-virtual-text`, `copilot-lualine` [S]. (`nvim-lint`, `markdown-preview.nvim` and
`render-markdown.nvim` left this list when the tree gained `lua/plugins/{linting,markdown}.lua`.)

Runtime confirmation on the current build — none of these commands or modules exist [R]:

```
:StartupTime :DB :DBUI :Kulala :Rest :GrugFar :Crates :VenvSelect :Neotest
:TestNearest :TestSuite :VimtexCompile :IlluminatePauseBuf :Yazi :Glow   → 0
require(): schemastore rustaceanvim crates vimtex neotest kulala octo
           treesitter-context grug-far illuminate yazi litee unimpaired
           friendly-snippets helm-ls vimtex                                 → false
```

Where one _did_ have a spec, the command appears — `:Octo`, `:MarkdownPreview`,
`:AerialToggle`, `:Trouble`, `:DapContinue`/`:DapNew`/`:DapToggleBreakpoint` all exist [R].

`ftplugin/agda.lua` is the same failure as `ftplugin/tex.lua`: a lazy.nvim-style plugin spec
(`ft = "agda"`, `dependencies`, `build`) parked in an ftplugin directory. `cornelis` is not
even in the closure, so the Agda interaction layer is gone twice over. Only
`ftplugin/matlab.lua` (`vim.b.slime_cell_delimiter`) is a real ftplugin [S].

## 3 Core tables

### 3.1 Formatting (`conform.nvim`)

`lua/plugins/lsp.lua:46-74` replaces LazyVim's `formatting.lua`. Runtime, after
`DeferredUIEnter` on the current build [R]:

```
formatters_by_ft = { yaml = yamlfmt
                     python = ruff_fix, ruff_format, ruff_organize_imports
                     markdown / markdown.mdx = prettier, markdownlint-cli2, markdown-toc }
formatters       = markdown-toc  (only when the buffer has a `<!-- toc -->` marker)
                   markdownlint-cli2 (only when the buffer already has markdownlint diagnostics)
default_format_opts = {}   -- unset ⇒ conform defaults (async, no quiet, lsp_format = fallback)
```

Gaps against LazyVim core + enabled extras: `lua = stylua`, `sh = shfmt`, `fish = fish_indent`
(LazyVim core, `plugins/formatting.lua:73-77`); the other 14 prettier filetypes from
`formatting/prettier.lua:11-28` (`css graphql handlebars html javascript javascriptreact json
jsonc less scss typescript typescriptreact vue yaml`) — yaml here goes to `yamlfmt` instead —
plus prettier's `has_parser`/`has_config` condition and `vim.g.lazyvim_prettier_needs_config`;
`nix = nixfmt`; `go = goimports, gofumpt` (binaries absent too); `sql* = sqlfluff` (binary
absent); the `injected` formatter override and LazyVim's `default_format_opts`
(`timeout_ms = 3000`, `async = false`, `quiet = false`, `lsp_format = "fallback"`).
**Format-on-save is not wired at all**: `vim.g.autoformat = true` (`options-lazyvim.lua:6`) is
only read by the `<leader>uf`/`<leader>uF` toggles (`keymaps-core.lua:136-167`); there is no
`BufWritePre` → `conform.format()` autocmd anywhere, so LazyVim's `LazyVim.format.register` +
autoformat contract is missing and `<leader>cf` (`keymaps-core.lua:113`) is the only path [S].

### 3.2 Linting (`nvim-lint`)

`lua/plugins/linting.lua` ports LazyVim's events/debounce/`linters` override, with
`BufReadPre`/`BufNewFile` replacing `LazyFile` (`docs/linting.md`); it is loaded in the current
build. Runtime [R]:

```
linters_by_ft = { fish = fish ; markdown = markdownlint-cli2 }   -- `linters` override table empty
autocmds      = BufWritePost / BufReadPost / InsertLeave, 100 ms debounce
```

LazyVim core supplies `fish`; the enabled extras add `dockerfile = hadolint`, `nix = statix`,
`go = golangcilint`, `sql* += sqlfluff` — all four rows are absent here, and of the four
binaries only `hadolint`/`statix` exist at all (home profile; `sqlfluff`, `golangci-lint` are
missing). Minor inconsistency: this spec has no `auto_enable`, unlike every other spec in the
tree.

### 3.3 LSP behaviour layer

`lua/config/lsp.lua` ports the LspAttach layer (diagnostics, keys with `has` gating, inlay
hints, LSP folds). Servers enabled by `lua/plugins/lsp.lua:9-28` [S]:

```
ast_grep basedpyright bashls copilot eslint gopls helm_ls jsonls lua_ls marksman ruff
texlab typos_lsp vtsls yamlls
```

Missing relative to the enabled extras: `nil_ls` (nix), `taplo` (toml), `dockerls` and
`docker_compose_language_service` (docker), `rust_analyzer` (rust), `r_language_server` (r), and
`jdtls` (java, normally via nvim-jdtls). **Every one of those first five has a working binary on
the wrapper's own PATH** — `nil`, `taplo`, `docker-langserver`, `docker-compose-langserver`,
`rust-analyzer` all resolve [R] — so they are one `vim.lsp.enable` line each, not blocked on
packaging. `jdtls` and `r-languageserver` do not exist. Several enabled servers run without the
extras' settings: `gopls`, `jsonls`, `yamlls`, `helm_ls`, `eslint`, `basedpyright`/`ruff`.
Key placement changed: LazyVim exposes `<leader>cr`/`<leader>cl`… globally with capability gates;
here they are buffer-local on attach (`config/lsp.lua:59,101-107`), so they do not appear in a
non-LSP buffer [R].

### 3.4 Treesitter

Grammars come from `_plugins.nix` (startup group, no `ensure_installed`); the port deliberately
drops `indent`/`folds`/`highlight` opts (`docs/lazyvim-core.md`). `general.lua:13-31` keeps the
disable list and the `sh`→bash registration, and adds local ftplugins. `vim.treesitter.language.add`
on the current build [R]: present `bash json5 helm dockerfile gitattributes git_rebase gitcommit
gitignore r`; **absent `git_config rnoweb ron ninja rst http graphql`** — all supplied by enabled
extras (`lang.git`, `lang.r`, `lang.rust`, `lang.python`, `util.dot`, `util.rest`).
`foldmethod` stays `indent` (`options-lazyvim.lua:45-47`) with nvim-ufo providing folds.

### 3.5 mini.*

Configured with bare `setup({})`: `mini.move`, `mini.surround`, `mini.bracketed`,
`mini.hipatterns`, plus LazyVim's mini.ai textobjects (`lazyvim-core.lua:266-313`). The extras'
tailwind/hipatterns behaviour and the mini.icons filetype additions are gone.

### 3.6 Core keymaps

`config/keymaps-core.lua` + `config/keymaps-picker.lua` cover LazyVim's core maps; the extras'
map inventory is in §2. Full `nvim_get_keymap` dump on the current build (473 maps, leader
resolved) confirms: core toggles all present (`<leader>us/uT/uz/uZ/uf/uF/uC/ud/uh/uI/uc/ul/uw`,
registered inside a `UIEnter` autocmd, `keymaps-core.lua:146-200`); absent relative to the extras
and the old live capture (`_keymap-parity.md`, still carrying un-ticked lines): `<leader>qq` Quit
All, `<leader>bp/bP/br/bl` (bufferline group), `<leader>sr` (grug-far), `<leader>cm` (Mason,
dropped with mason), `<leader>uN` (sidekick), the whole `<leader>d*` debug set bar `<leader>de`,
`<leader>t*` (test), `<leader>h*`/`<leader>H*` (harpoon), `<leader>a*` (sidekick), `<leader>R*`
(rest), `<leader>D` (DBUI), `<leader>gr` (octo review), `<c-.>`. `<leader>cs` differs (Trouble
symbols, not Aerial) and `gi/gI/gp/gP` are Snacks GitHub pickers, not octo's.

## 4 Confirmed defects (runtime-verified on the current build)

1. **`<leader>p` cannot work.** Three separate facts, all probed on the current build:
   `Snacks.picker.yanky_history` is nil and `Snacks.picker.yanky` is nil (`attempt to call a nil
value`); `require("yanky")` fails (`module 'yanky' not found`) because the yanky spec has
   keys but no `opts`/`after`, so `yanky.setup()` never runs; and the source name in yanky.nvim
   is registered only inside `yanky.setup()` (`yanky.nvim/lua/yanky.lua:61-64`), which LazyVim
   reaches as `Snacks.picker.yanky()` (`coding/yanky.lua:20`) [R][S]. Pressing it on the current
   build gives
   `E5108: Lua: ...av9cpxlgjxlvi05dh5vqbl-nvim/lua/plugins/lazyvim-core.lua:336: attempt to call
field 'yanky_history' (a nil value)` [R].
2. **The four dial maps are dead.** `dial.setup()` never runs (spec has keys only,
   `lazyvim-core.lua:316-325`), so `vim.g.dials_by_ft` is nil and the helper at
   `lazyvim-core.lua:7` indexes it before `require("dial.map")` on line 8 is reached. Current
   build: `vim.g.dials_by_ft = nil`, `require("dial.map")` / `require("dial.config")` both fail,
   and pressing `<C-a>` on a `1` gives
   `E5108: Lua: ...av9cpxlgjxlvi05dh5vqbl-nvim/lua/plugins/lazyvim-core.lua:7: attempt to index
field 'dials_by_ft' (a nil value)`, buffer unchanged [R][S]. The fix direction is settled by
   the source: dial.nvim 0.5.1 (`…-vimplugin-dial.nvim-0.5.1-unstable-2025-12-21`) ships
   `lua/dial/map.lua` and `lua/dial/config.lua` but never reads `dials_by_ft` — that global is
   LazyVim's own convention, so the spec must call `require("dial").setup()`, register the
   augends groups and set `vim.g.dials_by_ft` itself.
3. **`ftplugin/tex.lua` and `ftplugin/agda.lua` are inert plugin specs.** Neovim sources them as
   ftplugins and discards the returned table, so vimtex (in the closure) and cornelis (not in the
   closure) never load. Current build: `:VimtexCompile` = 0, `vim.g.vimtex_view_method = nil`,
   `require("vimtex")` = false [R].
4. **The lualine copilot component cannot resolve** (`lualine.lua:157`): copilot-lualine has no
   lze spec. Current build: `require("lualine.components.copilot")` →
   `module 'lualine.components.copilot' not found`, plus
   `lze.on_require: no plugin registered to load on require of 'lualine.components.copilot'` [R].
5. **Debugging is unusable**: no adapter exists (`codelldb`, `debugpy`, `dlv`, `lldb-dap` all
   missing from the wrapper PATH) and 17 of LazyVim's 18 `<leader>d*` maps are gone — the keymap
   dump has only `<leader>de` plus dap-view's `<leader>dv` [R].

## 5 Binary availability on the current build

`vim.fn.exepath` inside the wrapper [R]. The wrapper's own `runtimePkgs` are prepended to
`PATH`, so a store path means “the wrapper supplies it”; `/etc/profiles/per-user/saurabhj/bin`
means the home profile supplies it; `MISSING` means neither does.

| Binary                                                                                                                                                                                                                                                  | Result       | Consequence                                                                            |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | -------------------------------------------------------------------------------------- |
| `nil, taplo, docker-langserver, docker-compose-langserver, rust-analyzer`                                                                                                                                                                               | present      | extra-declared servers the config never enables (§3.3): one `vim.lsp.enable` line each |
| the 15 enabled servers' binaries (`texlab, helm-ls, vtsls, yamlls, marksman, gopls, basedpyright, ruff, bash-language-server, lua-language-server, ast-grep, typos-lsp`, plus the `vscode-langservers-extracted` and `copilot-language-server` bundles) | present      | no enabled server is silently dead for want of a binary                                |
| `stylua, shfmt, fish_indent, nixfmt, prettier, prettierd, yamlfmt, markdownlint-cli2, markdown-toc`                                                                                                                                                     | present      | conform/nvim-lint coverage gaps are config rows, not packaging                         |
| `hadolint, statix, eslint, git`                                                                                                                                                                                                                         | home profile | reachable today, but not pinned by the wrapper                                         |
| `sqlfluff, golangci-lint, goimports, gofumpt, eslint_d`                                                                                                                                                                                                 | **MISSING**  | blocks the normalised sql/go rows                                                      |
| `jdtls, r-languageserver, R, bacon-ls`                                                                                                                                                                                                                  | **MISSING**  | blocks `lang.java` / `lang.r`                                                          |
| `codelldb, debugpy, dlv, lldb-dap`                                                                                                                                                                                                                      | **MISSING**  | blocks every DAP adapter                                                               |

## 6 Verified already correct on the current build

`editor.mini-move` (`<M-j/k/h/l>`), `editor.snacks_picker` (11/11 maps), `lang.markdown`
(conform rows, markdownlint row, marksman, `<leader>cp`, `<leader>um`, `:MarkdownPreview`),
`lang.git` grammars minus `git_config`, `util.dot` core parts, `coding.yanky` maps (the picker
defect is §4.1), `ai.copilot` ghost-text/blink wiring, `dap.core` `<leader>de` semantics
(matches the old capture), the LSP behaviour layer and core keymap port, the `<leader>uf/uF`
toggle plumbing.

## 7 Uncertainties

- Old-editor binaries cannot be re-verified: the mason tree is gone. The 53-package list in
  `MIGRATION-GAPS.md` is a [D] claim taken before the switch; treat it as indicative.
- Whether the old editor's `<leader>p` also errored is not decidable: its LazyVim commit calls
  `Snacks.picker.yanky()`, and the snacks build pinned by `lazy-lock.json` is no longer on disk.
  The current nix snacks (`2.31.0-unstable-2026-05-25`) has no yanky source outside yanky.nvim.
- Home-profile binaries (`hadolint`, `statix`, `eslint`) were probed with this shell's `PATH`;
  a login shell could in principle differ, though the profile is on it.
- `render-markdown.nvim` was verified to load and map `<leader>um` on an unnamed markdown
  buffer; opening a real `*.md` file headless did not exit within 90 s twice (unclear whether
  marksman, `markdownlint-cli2` or the probe itself), so the on-disk markdown path is untested.
- The server enable list in §3.3 is static ([S]): `vim.lsp.config` was empty under manual event
  firing in a probe, and the lazily-loaded `after` function was not observed running headless.

## 8 Follow-ups (not done here)

- Decide the fate of the closure plugins with no spec (§2.1 list; ~26 counting the vim-dadbod
  trio individually): spec them, or drop them from the closure so the wrapper stops shipping dead
  weight.
- Fix §4 items 1–4 (each a small, local edit); item 5 is the larger DAP decision.
- Enable `nil_ls`, `taplo`, `dockerls`, `docker_compose_language_service`, `rust_analyzer` — the
  binaries ship with the wrapper (§5).
- Wire format-on-save, or drop `vim.g.autoformat` and the toggle maps so the config does not
  advertise a contract conform never honours.
- Move `ftplugin/{tex,agda}.lua` out of `ftplugin/` (or delete them) and re-check
  `_plugins.nix`'s “the config's own ftplugins” comment, which currently refers to them by
  location rather than by effect.
- Cross-check the extras' remaining maps against `_keymap-parity.md`'s un-ticked lines once the
  plugin specs exist.

## Status after the parity pass

Closed since the audit above:

- `coding.yanky` and `editor.dial` defects. `<leader>p` called a nonexistent
  `Snacks.picker.yanky_history` — the real source is `Snacks.picker.yanky`, registered by
  yanky.nvim itself in its `setup`, so it only exists once the plugin has loaded. The dial maps
  threw on `vim.g.dials_by_ft`, which the extra's own `config` sets; the augends and groups are
  now ported from `extras/editor/dial.lua`.
- Free LSP servers enabled: `nil_ls`, `taplo`, `dockerls`, `docker_compose_language_service`.
  All four binaries were already on the wrapper's PATH.
- `lang.rust`: `rustaceanvim` and `crates.nvim` in `plugins.rust`. Probe-verified on a real crate:
  `rust-analyzer` attaches and `:RustLsp` exists. `rust_analyzer` stays out of `lsp.lua` because
  rustaceanvim owns it.
- `lang.tex`: `vimtex` in `plugins.tex`, carrying the five globals that were stranded in the inert
  `ftplugin/tex.lua` (view_method zathura_simple, compiler_method latexmk, quickfix_mode 0,
  view_geometry_locate, view_enabled).
- `editor.grug-far`: spec in `lazyvim-core.lua` with `<leader>sr`; the name had to be the pack
  directory `grug-far.nvim`, not the nix attribute `grug-far-nvim`.
- Format-on-save restored, and conform's table extended to LazyVim's core rows plus the prettier
  extra's filetypes and condition.
- `nvim-lint` specced as `plugins.linting`, and the markdown formatter and linter binaries added
  to `_wrapper.nix`'s runtimePkgs.

Still open:

- `latexmk` is not installed, so vimtex cannot compile. `pplatex` is absent too, so
  `vimtex_quickfix_method` falls back to `latexlog`.
- The unspecced-plugin list above is the triage queue; nothing in it is wired.
