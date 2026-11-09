# Yazi previews

## Native previewers where they work, pistol for text-shaped formats

**Id:** f0129f1f-2376-4b52-9679-faa70ca0199d
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** yazi 26.9.1 default `yazi.toml` (`previewers`), piper 26.9.1 `main.lua`, pistol 0.6.0 README and source, awesome-yazi previewer list, measured previews of a generated `.docx`, `.sqlite`, `.png` and `.pdf`
**Revisit when:** yazi gains native office or database previews, or pistol gains built-in handlers for them
**Verification:** corroborated — piper wraps the command's stdout in `ui.Text`, pistol printed the `file` description for image and PDF files and the converted text for office and SQLite files only once its config named a converter

Yazi's native previewers cover folders, text and code, JSON, images, SVG, video, PDF, fonts, empty files and archives, so they keep those types. Pistol takes only what no native previewer covers: office documents, EPUB, RTF and SQLite, through a piper previewer rule. The tools each side calls live in the aspect that owns the previewer.

**Reason:** the native previewers are better where both exist. They draw images through the terminal's graphics protocol, which a text pipe cannot reach; they run asynchronously and cache by file, with image preloaders warming the cache before the cursor arrives; and they fit their output to the pane, where pistol prints a stream with no width. Pistol is the reverse case — a stdout text producer with nothing built in for office or database formats, since its internal writers cover only text (chroma) and archives — so it earns its place by naming converters for the types that have no native handler. `piper` is the pipe because it ships in nixpkgs.

**Rejected alternatives:** `faster-piper.yazi` — it adds caching and paging for expensive previews, but it is not in nixpkgs, needs its own derivation, and its Windows support is unconfirmed; it accepts piper's command syntax, so switching later is one line. One awesome-yazi previewer plugin per type (`mediainfo`, `lsar`, `rich-preview`) — it multiplies setup and runtime tools where one pipe and one config cover the long tail. Routing images, PDF or SVG through pistol — the association can only print escape bytes for a terminal to place, and yazi renders that stdout as text cells.

## `programs.pistol.associations` has one owner, in the `previews` aspect

**Id:** 7c1a54c6-9a2b-4a1e-8f36-2e0b6f2d1c93
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** Home Manager `modules/programs/pistol.nix` (`home.file."${configDir}/pistol/pistol.conf"`), `lib/types.nix` `lines` merge, evaluated `home.file."/home/saurabhj/.config/pistol/pistol.conf".text`
**Revisit when:** Home Manager gives `programs.pistol` a merged-per-association option, or pistol gains its own layering
**Verification:** corroborated — two definitions produced one file containing both rule sets, the second appended after the first, with no evaluation error

`modules/shell/previews.nix` holds the only definition of `$XDG_CONFIG_HOME/pistol/pistol.conf`, together with the `preview-image` helper and the converters its associations name. Both hosts select `previews` beside `cli`; neither the shell aspect nor the yazi aspect configures pistol.

**Reason:** Home Manager's `programs.pistol` writes `home.file."<configHome>/pistol/pistol.conf"`, the same target `xdg.configFile."pistol/pistol.conf"` resolves to. That `text` is `types.lines`, so a second definition concatenates instead of failing, and pistol takes the first pattern that matches — which makes rule precedence depend on the order aspects appear in the host list. The associations also serve two consumers, fzf's shell preview and yazi's piper, so the file cannot belong to either one alone.

## Associations are Go regexes; yazi `mime` patterns are globs

**Id:** e3f8087a-5b47-4d24-9c1f-6a2d0d9b71ee
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** pistol 0.6.0 README ("interpreted by the built-in `regexp.match`"), measured `pistol /tmp/pt.sqlite` against a brace pattern and a regex pattern
**Revisit when:** pistol switches to glob matching for associations
**Verification:** corroborated — the brace pattern fell through to the `file` description; `application/(vnd\.|x-)sqlite3` printed the schema

`application/{vnd.sqlite3,x-sqlite3}` left SQLite files on pistol's `file` fallback because pistol matches association patterns as unanchored Go regexes, where that brace form is not a brace expansion. `application/(vnd\.|x-)sqlite3` matches. Yazi's own `mime` patterns in the piper rule do accept braces, so the two pattern dialects differ even where they name the same types.

**Reason:** the two match in different places. `text/*` works in pistol only because the regex is unanchored and the prefix matches; a new pattern should be written as the regex it is rather than as the glob it looks like.

## Pistol config lines are whitespace-split; `sh:` is what enables a shell

**Id:** 4b9a2f80-1c73-4e5a-9d67-8f2b0c5e6a41
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** pistol 0.6.0 `previewer.go` (`strings.Fields`, `if p.Command == "sh:"`), measured runs against a quoted and an unquoted association
**Revisit when:** pistol switches to a shell-quoting parser
**Verification:** corroborated — a quoted association failed with "No such file or directory" for a path that exists; the unquoted form ran, and the PDF rule only produced document text once prefixed with `sh:`

**Reason:** both failure modes are silent in the config text and loud only at preview time. The shell mode also carries the pane width: piper exports its preview area as `w` and `h`, fzf exports `FZF_PREVIEW_COLUMNS` and `FZF_PREVIEW_LINES`, so one association reads `''${w:-''${FZF_PREVIEW_COLUMNS:-100}}` and fits both consumers.

Pistol splits each config line with `strings.Fields`, so an argument written in double quotes keeps the quote characters and a quoted path never resolves. It also runs the first field directly unless that field is `sh:`, which is the only mode where pipes, `|` and environment expansion work. The associations in `modules/shell/previews.nix` therefore name store paths bare, and every rule that pipes or reads a variable starts with `sh:`.

## Markdown previews key on the file path, not the MIME type

**Id:** 5d0c7e93-2a48-4b16-8c33-9e71f4a2b6d8
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Source:** measured `file -b --mime-type` and `pistol` output on a `.md` file, yazi 26.9.1 default previewers
**Revisit when:** the MIME database reports markdown as its own type, or yazi's mime-ext table maps `.md` before the rule runs
**Verification:** corroborated — `file` reported `text/plain` for a `.md` file, so a `text/markdown` association fell through to the `text/*` rule and printed source with line numbers

**Reason:** `file(1)` classifies markdown as `text/plain`, and a MIME-keyed rule sits behind the generic `text/*` one. `glow` also emits OSC 8 hyperlinks, which a preview pane draws as literal escapes, so the shared `preview-markdown` helper strips them before the text reaches either consumer.

The rendered markdown rule for pistol is `fpath = ".*\\.(md|markdown)$"` and yazi's is `url = "*.{md,markdown,mdx}"`. Neither keys on `text/markdown`.

## Tabular data goes to duckdb; markdown has a browser and a renderer

Yazi previews `*.{csv,tsv,parquet,xlsx,duckdb}` through the `duckdb` plugin, with `gh`/`gl` scrolling columns and `K` toggling between the table and DuckDB's summary. Markdown splits in two: the `preview-markdown` helper renders it inside a preview pane with glow, while `mdterm` is installed as the interactive browser for reading a document at full width.

**Id:** 9a7e14d2-6b3c-4f58-8d21-5c0e7f3a8b64
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** duckdb.yazi README, measured `duckdb` 1.5.5 on a 7.2 MB / 200k-row CSV (59 ms for a 20-row preview, 182 ms for `SUMMARIZE`), nixpkgs `mdterm` 2.0.0 metadata
**Revisit when:** duckdb's startup cost regresses materially, or yazi gains native Parquet support
**Verification:** corroborated — the timings come from the installed CLI, and the plugin's own rules were mirrored from its README

**Reason:** duckdb is the only previewer here that reads Parquet, and its `xlsx` reading closes the spreadsheet gap that pandoc cannot fill; at 59 ms a preview is as fast as a process spawn. Parquet and Excel are otherwise invisible to both yazi and pistol. Markdown needs two shapes rather than one tool: glow fits a pane and takes a width, whereas `mdterm` is an interactive browser with a table of contents, in-document search and inline images, which only makes sense at full width.

**Rejected alternatives:** routing `*.json` and `*.txt` through duckdb as its README suggests — a config file would render as a table, and a prose `.txt` would lose its text preview. `mdterm` or `mdcat` as the pane renderer — both are full-width views, and their inline images and OSC 8 links cannot land in a text preview. `lsar` — the native archive previewer already lists archive contents.

## jaq renders JSON, duckdb renders the tabular types, helpers pin their PATH

The JSON association runs `jaq -C -S .`, the binary tabular types (`*.parquet`, `*.duckdb`, `*.db`) go to a `previewDuckdb` helper, and every previewer helper is a `writeShellApplication` with its own `runtimeInputs` rather than a bare script that borrows the ambient PATH.

**Id:** 2f6c8b1d-7e94-4a03-b5d8-0c1a3e9f7d25
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** jaq 3.1.2 `--help` (`--from`/`--to` for raw, json, cbor, yaml, toml, xml, csv, tsv), measured jq 93 ms vs jaq 67 ms on a 1.5 MB JSON file, duckdb box output on a generated Parquet and a duckdb database
**Revisit when:** a previewer needs a jq feature jaq lacks, or a helper's tool moves into the previews aspect's own package list
**Verification:** corroborated — both renderers produced the expected output on generated files, and the timings are wall-clock from the installed binaries

**Reason:** jaq matches the flags the rule uses (`-C`, `-S`, explicit `.` filter) while being roughly 30% faster to start, and it is the tool to reach for when YAML, TOML or XML has to be read as data. duckdb covers Parquet and database files, which no text converter reads at all. Pinning each helper's `runtimeInputs` keeps a previewer working when the aspect that happens to install a tool is deselected.

**Rejected alternatives:** `bat -l json` — it only highlights, so minified JSON stays one line. Routing `*.yaml`, `*.toml` and `*.xml` through `jaq --from` — the normalised output drops comments and anchors, which is worse than the highlighted source for reading a config. `xlsx` in the pistol helper — DuckDB reads Excel through its spatial extension, which installs from the network at preview time.

## Images decode once at the pane's size, vectors are rasterised, renderings are cached

`previewImage` reads the pane (fzf's `FZF_PREVIEW_COLUMNS`/`LINES`, falling back to piper's `w`/`h`), rasterises SVG with resvg at the pane's pixel width, pre-scales photos over 1.5 MB with magick, draws through kitty's protocol on kitty, WezTerm and Ghostty, and otherwise renders with chafa into `$XDG_CACHE_HOME/preview-images`, keyed by path, mtime, size and geometry.

**Id:** 4c1d7a90-2be8-4f36-9a71-6d5e0c8b9f13
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** measured 2026-10-29 with chafa 1.18, resvg 0.48.1 and magick 7.1.2 — chafa 310 ms on a 12-megapixel photo, 227 ms on a 57 KB complex SVG; resvg raster 85 ms then chafa 22 ms; magick resize 315 ms; cached rendering 49 ms. kitty's icat documentation: formats beyond PNG/JPG/GIF/BMP/TIFF/WEBP need ImageMagick on PATH.
**Revisit when:** kitty gains SVG decoding, or chafa's rasteriser learns to honour a target size
**Verification:** corroborated — cold and warm timings measured against the helper itself, before and after the change

**Reason:** the two paths disagreed, which is what made previews look inconsistent. `kitten icat` cannot read SVG without ImageMagick on PATH, so SVG fell through to chafa's own rasteriser, which ignores the pane and costs three times a resvg pass — an SVG therefore drew as symbols at a different scale than a photo. Sizing had a second asymmetry: the helper read only fzf's variables, so piper's `w`/`h` were ignored. Caching is what makes the slow first decode tolerable: a 12-megapixel photo costs ~300 ms cold and 49 ms warm.

**Rejected alternatives:** chafa-only — it never draws a real image where the terminal can; magick as the SVG rasteriser — 315 ms against resvg's 85 ms; libvips thumbnails — 262 ms startup, no better than magick; caching icat's escape output — it re-transmits the same bytes, so there is nothing to save; always pre-scaling with magick — the resize alone costs as much as chafa on the full image, so it only pays because the result is cached.
