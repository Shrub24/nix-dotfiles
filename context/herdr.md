# Herdr

## Delegation is herdsman; pane state is Herdr's own integration

**Id:** 955f78bb-d9d0-44ca-a1e8-690b7aeaf111
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

`pi-herdsman` replaces `pi-subagents`, which is gone outright: no extension row, no `subagents` settings block and no rendered config remain. What that block carried lives where its owner reads it. The disabled roles are in herdsman's own `disabledDefinitions`, and a child's extensions and provider are in its agent definition.

The official `herdr integration install pi` replaces `@narumitw/pi-herdr`. The integration is a file Herdr writes to `~/.pi/agent/extensions/herdr-agent-state.ts`, so it stays imperative and is re-run after a Herdr upgrade. Two publishers of pane metadata never run at once: the swap is one change.

**Alternatives:** unknown.
**Reason:** each setting sits with the component that reads it, so no block of the retired extension is left to drift.

## Plugin-owned config tables are declared, not merged

**Id:** d5da94a5-b26f-428c-9e52-3b68ed3361c5
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

Herdr and its plugins rewrite `config.toml` by renaming a temporary file over the real path, so a store symlink breaks them with `EACCES` in `/nix/store`. The file is therefore rendered from `programs.herdr.settings` but written as a real file at activation. The blocks herdr-radar owns are re-applied in the same step, so a switch re-seeds the published keys and the plugin reinstalls its own layout rather than leaving a stale copy behind.

TOML allows a table once, so declaring one is the way to keep it. `[theme.custom]` is declared so that Herdr's theme name stays this repository's choice rather than the panel-fill value the plugin installs with it; the plugin finds a foreign table and skips its theme block. The sidebar panel is deliberately not declared: the plugin rebuilds that block per appearance and its daemon re-probes the desktop's, so a Nix-declared copy pins one appearance. While the table is ours, the plugin also reads the panel as someone else's and disables its own ordering, which is how a declared panel quietly costs the activity sort.

**Alternatives:** unknown.
**Reason:** a store link breaks the writers, and a declared sidebar panel costs the plugin's activity sort.
