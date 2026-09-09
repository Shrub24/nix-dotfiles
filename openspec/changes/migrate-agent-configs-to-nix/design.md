# Design

## Context

`modules/agents/herdr.nix` and `modules/agents/pi.nix` each publish one Home
Manager aspect. Both set a package override and then hand the entire
configuration directory back to the application with a single out-of-store
symlink:

```nix
xdg.configFile."herdr".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/herdr";
home.file.".pi/agent".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/pi";
```

Home Manager at the pinned revision already ships
`modules/programs/herdr.nix` and `modules/programs/pi-coding-agent.nix`. The
Herdr module's `settings` option renders `$XDG_CONFIG_HOME/herdr/config.toml`
through `pkgs.formats.toml` and reloads the running server through `onChange`.
The Pi module's `settings`, `keybindings`, `models`, and `context` options
render four files under `programs.pi-coding-agent.configDir`
(`~/.pi/agent` by default) through `pkgs.formats.json`.

## Goals / Non-Goals

**Goals:**

- Both applications read their configuration from the Nix store.
- The configuration is reproducible from the flake with no out-of-store
  symlink, no hardcoded home path in the module, and no `../apps/` dependency.
- The runtime state that these applications genuinely own keeps working, in a
  directory that is not version-controlled.

**Non-Goals:**

- Making Pi's `auth.json`, project trust store, sessions, or package checkouts
  declarative. They are credentials and history, not configuration.
- Making Herdr's plugin registry declarative. `config.toml` has no plugin list;
  Herdr rewrites `plugins.json` wholesale on every install, enable, and update.
- The same migration for OpenCode (`modules/agents/opencode.nix`), which
  symlinks `../apps/opencode` and `../apps/agents`.
- Relocating `~/.pi/agent` to `$XDG_CONFIG_HOME`.

## Decisions

### Nix owns the settings files; the store copy is read-only

`programs.herdr.settings` and `programs.pi-coding-agent.settings` render store
paths, so the applications cannot write back to them.

Pi's write path is `FileSettingsStorage.withLock`, which takes a lock beside
the target and then calls `writeFileSync` on it. Against a store symlink that
raises `EACCES`; `SettingsManager.enqueueWrite` catches the failure into an
error list, and `reportSettingsErrors` prints it only from `pi config` and
`pi install`/`remove`/`update`. Interactive startup never reports it. The
observable loss is therefore: `/theme`, the `pi config` selector, and
`pi install` no longer persist. Each of those becomes a Nix edit.

The usual objection — that declaring `settings.packages` makes package
installation impossible — does not hold. `DefaultResourceLoader` calls
`DefaultPackageManager.resolve()`, and `resolvePackageSources` installs any
configured source whose `node_modules` path is missing or whose version no
longer matches the configured range. Adding a package to the Nix list and
switching is enough; the next Pi start materialises it into
`~/.pi/agent/npm/`.

Herdr's `herdr config reset-keys` subcommand rewrites `config.toml` and will
fail against the store. That is acceptable for a single-user host whose config
is 11 lines; the same edit goes in the module.

### Paths derive from `config.home.homeDirectory`

`settings.json` contains roughly forty absolute paths into
`~/.pi/agent/npm/node_modules/...` for `subagentOnlyExtensions`, plus one
device-local entry for the `pi-subagents` checkout. Rendering those as Nix
strings built from `config.home.homeDirectory` removes the hardcoded username
and the `../../../../mnt/LinuxData/...` relative climb. The dev-worktree
symlink target for `extensions/omniroute` stays a literal path: it points at a
working tree outside this repository and is genuinely host-local.

### Draw the declarative boundary at "does the application rewrite this file?"

The files split cleanly along that line, which is also the line that decides
whether a store symlink breaks something.

| Nix-owned | Application-owned |
|---|---|
| `herdr/config.toml` | `herdr/plugins.json`, `herdr/plugins/`, `herdr/session.json`, `herdr/release-notes.json`, `herdr/.plugins.lock`, `herdr*.log`, `herdr*.sock` |
| `pi/settings.json`, `pi/mcp.json`, `pi/pi-fff.json`, `pi/pi-starship.toml`, `pi/pi-auto-permissions/config.json`, `pi/extensions/subagent/config.json`, `pi/agents/`, `pi/extensions/omniroute` | `pi/pi-tool.json`, `pi/pi-stamp.json`, `pi/pi-herdr.json`, `pi/extensions/pi-tool-display/config.json`, `pi/auth.json`, `pi/trust.json`, `pi/mcp-cache.json`, `pi/models-store.json`, `pi/run-history.jsonl`, `pi/sessions/`, `pi/git/`, `pi/npm/`, `pi/fff/`, `pi/missions/`, `pi/intercom/` |

`auth.json` and the project trust store are excluded on ownership grounds as
well as rewrite grounds: they are credentials and per-machine approval state,
and they belong with the other user-scoped runtime state rather than in a
public repository.

Four extension settings files are excluded on rewrite grounds alone, and the
reason is stronger than “the app edits them”. `@narumitw/pi-tool`,
`@narumitw/pi-stamp`, `@narumitw/pi-herdr`, and `pi-tool-display` all save with
a temporary file plus a rename — `rename(temporaryPath, path)` in
`@narumitw/pi-tool/src/settings.ts:181`, and `renameSync(tmpFile, configFile)` in
`pi-tool-display/src/config-store.ts:279`. `rename()` replaces the *symlink*,
not the link target, so a declared file would be swapped for a real file
without an error, and the next activation would either refuse to clobber it or
overwrite the user's change. Pi's own `settings.json` fails differently:
`FileSettingsStorage.withLock` calls `writeFileSync` on the path, which raises
`EACCES` against a store symlink and is caught into a reported warning. A loud
failure is an acceptable cost for declarative configuration; a silent one is
not.

Herdr has the same property as the four: its live `config.toml` gained
`ui.sidebar.agents.rows` at runtime, so the UI persists settings into the file
the module renders. It stays Nix-owned because the whole point of the Herdr
half of this change is a declarative `config.toml`, but task 5.5 verifies that
a UI change leaves the store symlink intact rather than replacing it. If Herdr
turns out to rename instead of write, the honest fallback is to move
`herdr/config.toml` into the application-owned column and drop
`programs.herdr.settings`.

### Keep `~/.pi/agent` as the agent directory

`programs.pi-coding-agent.configDir` would allow moving the directory to
`$XDG_CONFIG_HOME/pi/agent`, which would be the tidier location. It is
rejected: `~/.pi/agent` is upstream's default, moving costs an exported
`PI_CODING_AGENT_DIR` plus a rewrite of every absolute path in `settings.json`,
and the project-local `.pi/` convention that Pi already uses in this repository
is unrelated. No benefit justifies the churn for a single-user host.

### Pi agent definitions are repository-owned prompt text

The seven subagent definitions were inlined as `subagents.agentOverrides` in
`settings.json`, which forces every prompt change through a JSON string list
typed by hand. They move to `modules/agents/pi/agents/*.md` as files whose
frontmatter carries the override values.

They do not belong in `~/.agents`. That directory is the cross-tool agent
directory — it already holds OpenCode's skills and is symlinked by
`modules/agents/opencode.nix:23` — so Pi-specific personas there are scope
pollution in a directory this repository does not own. Pi's own agent dir is
scanned as well: `pi-subagents` builds its user discovery list as
`[...extraUserAgentDirs(), ...userScanDirs.dirs, ~/.pi/agent/agents, ~/.agents]` (`src/agents/agents.ts:2578`), so `~/.pi/agent/agents` is a
first-class location and only the *eject target* prefers `~/.agents`
(`src/agents/agents.ts:2609`).

Two consequences worth recording:

- **Overrides outrank frontmatter.** `settings.json` overrides are applied on
  top of a matching custom agent and replace the same frontmatter fields. An
  `eject` copies the *bundled* file, not the effective configuration, so the
  override values must be ported into the frontmatter before
  `subagents.agentOverrides` is deleted. Removing the overrides first silently
  strips the agents down to their bundled tool lists — 5 to 8 tools instead of
  15 to 27.
- **Prompt text is excluded from mdformat.** `modules/flake/tooling.nix`
  excludes `modules/agents/pi/agents/**`. mdformat preserves the YAML frontmatter
  through `mdformat-frontmatter`, but it renumbers ordered lists to `1.`
  repeatedly, which rewrites prompt content and makes byte-level comparison
  against upstream's bundled agents impossible.

### Agent-relative extension paths keep the definitions host-independent

`subagentOnlyExtensions` entries beginning with `./` or `../` resolve against
the definition file's own directory (`resolveAgentRelativeExtensionPaths`,
`src/agents/agents.ts:1995`), and `subagent({ action: "get" })` confirms the
resolved absolute paths. So `../npm/node_modules/pi-cbm/src/index.ts` inside
`~/.pi/agent/agents/*.md` reaches the installed package without a hardcoded home
directory. That is what makes it possible to hold the definitions in the
repository at all: a rendered Nix value could interpolate
`config.home.homeDirectory`, but a static Markdown file cannot.

### Settings-level defaults absorb the per-agent repetition

- `subagents.defaultExtensions = [ ]` replaces seven identical
  `extensions: [ ]` entries. It still disables ambient extensions for every
  child, including model-provider extensions — which is why every definition
  lists `extensions/omniroute` in `subagentOnlyExtensions`.
- `subagents.defaultProvider = "omniroute"` resolves the five bare model ids
  (`explorer`, `smart`, `smart-budget`, `budget`, `coder-high`) so they do not
  depend on which model the parent session happens to be running.
- `allowNestedSubagents: false` was deleted rather than ported. It was a no-op:
  `fanoutAuthorized` requires `allowNestedSubagents === true`
  (`src/runs/shared/child-tool-plan.ts:422`).

### Two fields exist only in frontmatter

`advertise` cannot be reached from settings — "Advertisement is not supported
through settings overrides or runtime registration" — so parent-prompt discovery
of these seven agents was impossible before the port. Direct MCP tool selection
has the same shape: subagents only receive direct MCP tools when `mcp:` entries
are listed in their frontmatter, and a global `directTools` setting is not
sufficient.

### The pi-subagents extension config is at the wrong path

pi-subagents reads its extension config from
`~/.pi/agent/extensions/subagent/config.json`
(`src/extension/config.ts:194`). The live file sits at
`extensions/pi-subagents/config.json`, which nothing reads — so its
`fleetView` and `modelExclusions.defaultTtlMs` values are currently inert. The
port relocates it to the path the extension resolves and renders that from Nix.
The neighbouring `extensions/pi-tool-display/config.json` and
`pi-auto-permissions/config.json` were checked and are already at the paths
their extensions resolve (`src/config-store.ts:23`, `config.ts:8` respectively).

### Omit `lastChangelogVersion`

Pi branches on that key at startup. Present and stale, it re-displays the
changelog and re-attempts a write that cannot succeed. Absent, Pi takes its
fresh-install branch and stays quiet. The committed value in `apps/pi` today
(`0.85.1`) is therefore dropped rather than carried over.

### Herdr gets its own capability, and `add-herdr-pi-native` is deleted

`openspec/changes/add-herdr-pi-native/` proposed adding Herdr requirements to
the `pi-agent-skeleton` capability. Syncing that delta would file Herdr's
configuration contract under a Pi capability, and this change would then have
to remove it. Its implemented part — the module and package swap — is already
in the tree, so deleting the change loses no work and avoids a merge/split
round trip. Herdr's contract lands in a new `herdr-config` capability instead.

The existing `pi-agent-skeleton` capability keeps its path: OpenSpec does not
rename capabilities. Its Purpose is rewritten in place, since "preserves a
small, stable Pi package integration that can be re-enabled later" no longer
describes it.

## Risks / Trade-offs

- [Pi cannot persist its own settings writes] → Accepted and documented above.
  The Nix list is the source of truth for `packages`, `theme`, `enabledModels`,
  and the subagent overrides. `pi install -l` remains available for
  project-local experimentation, which writes `.pi/settings.json` in the
  project rather than the store-owned file.
- \[Deleting `agentOverrides` before porting the values strips agent tools\] →
  Porting is an explicit task ordered before the removal (`tasks.md` 3.2 before
  3.3), and the verification step compares the effective configuration from
  `subagent({ action: "list" })` against the pre-migration values.
- [Herdr's plugin checkouts are not reproducible] → Accepted. Herdr exposes no
  declarative plugin list; its 12 installed plugins continue to be installed
  and versioned by Herdr itself.
- [Moving ~1.7 GB could be slow] → The move is a rename within one filesystem.
  The Herdr server must be stopped first because its config directory holds
  live sockets; Pi may be left running.
- \[A future Pi or Herdr release could start rewriting a file this change
  declares\] → The boundary is documented in `ARCHITECTURE.md`, and a read-only
  store path fails loudly rather than silently diverging.
- \[The pushed `../apps/` directories are not version-controlled\] → After
  migration their remaining contents are runtime state, which is the correct
  place for them.

## Migration Plan

1. Apply the module changes, then stop the Herdr server.
1. Remove the two out-of-store symlinks.
1. Move `~/.dotfiles/apps/pi` to `~/.pi/agent` and `~/.dotfiles/apps/herdr` to
   `~/.config/herdr`.
1. Delete the configuration files now owned by Nix from both moved
   directories.
1. `nh home switch -c saurabhj`, then confirm rendered files are store
   symlinks, both applications start, and Herdr's 12 plugins are still
   registered.
1. Delete the empty `~/.dotfiles/apps/pi` and `~/.dotfiles/apps/herdr`.

## Rollback

Restore the `mkOutOfStoreSymlink` stanzas in both modules, move the two
directories back to `../apps/`, and re-switch. No state is rewritten by this
change: Pi and Herdr read the same directory paths before and after, so
`npm/`, `plugins/`, `sessions/`, and `trust.json` carry over untouched.
