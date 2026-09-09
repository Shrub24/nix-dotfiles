# Migrate Herdr and Pi configuration into Nix

## Why

`~/.config/herdr` and `~/.pi/agent` are each a single out-of-store symlink into
`../apps/`:

```
~/.config/herdr -> ~/.dotfiles/apps/herdr
~/.pi/agent     -> ~/.dotfiles/apps/pi
```

Neither application's configuration is declarative, and both directories hold
their whole runtime footprint — roughly 1.7 GB, dominated by Pi's `npm/`
(905 MB) and `sessions/` (52 MB) and Herdr's `plugins/` (745 MB).

Home Manager already ships native modules for both at the pinned revision —
`programs.herdr` and `programs.pi-coding-agent` — and the repository currently
uses them only for the package override. The rendered-file options
(`programs.herdr.settings`, `programs.pi-coding-agent.settings`) are unused.

## What Changes

- **Herdr configuration** — `programs.herdr.settings` renders
  `~/.config/herdr/config.toml` (174 B today). The
  `xdg.configFile."herdr"` out-of-store symlink is removed.
- **Pi settings** — `programs.pi-coding-agent.settings` renders
  `~/.pi/agent/settings.json` (9.7 KB today). The ~40 absolute
  `subagentOnlyExtensions` paths are rebuilt from `config.home.homeDirectory`
  rather than hardcoded, and the single relative
  `../../../../mnt/LinuxData/...` entry becomes absolute.
- **Pi residual surfaces** — `home.file` entries for the configuration files
  upstream Home Manager does not cover: `mcp.json`, `pi-fff.json`,
  `pi-tool.json`, `pi-stamp.json`, `pi-starship.toml`, the two extension
  `config.json` files, and the `extensions/omniroute` symlink.
- **Pi agent definitions** — the seven subagent definitions currently inlined
  as `subagents.agentOverrides` in `settings.json` become repository-owned
  Markdown files under `modules/agents/pi/agents/`, rendered to
  `~/.pi/agent/agents/`. Their frontmatter carries the override values, and
  `subagents.agentOverrides` is removed. They leave `~/.agents`, which is the
  cross-tool agent directory that `opencode.nix` already owns and shares with
  OpenCode.
- **State relocation, not state ownership** — the two directories stop being
  symlinks. Their runtime state moves to the paths those symlinks already
  resolved to, so no file outside the two applications observes a changed
  path.
- **Superseded change** — `openspec/changes/add-herdr-pi-native/` is deleted.
  Its module swap landed, its spec delta was never synced, and its Herdr
  requirements are filed under the `pi-agent-skeleton` capability, which this
  change would then have to remove again.

## Capabilities

### New Capabilities

- `herdr-config` — Herdr's `config.toml` is rendered declaratively by the
  native Home Manager module. The plugin registry, plugin checkouts, session
  state, logs, and sockets remain Herdr-owned.

### Modified Capabilities

- `pi-agent-skeleton` — Pi's settings, extension configuration files, and
  subagent definitions are rendered by Nix. Pi's runtime state —
  authentication, project trust, sessions, package checkouts, caches — remains
  unmanaged. The capability's stated purpose changes from a disabled package
  skeleton to a declarative agent configuration.

## Impact

- Files: `modules/agents/herdr.nix`, `modules/agents/pi.nix`,
  `modules/agents/pi/agents/*.md`, the `modules/agents/pi/agents/**` exclusion
  in `modules/flake/tooling.nix`, and a durable decision in `ARCHITECTURE.md`.
  No host-composition, system-manager, NixOS, or secrets change.
- Blocks on nothing. Home Manager at the pinned revision already provides both
  modules, so no flake input update is required.
- Deployment requires one directory move per application and must stop the
  running Herdr server first (its config directory holds live sockets).
- Out of scope: `modules/agents/opencode.nix` symlinks `../apps/opencode` and
  `../apps/agents` with the same pattern. Those are separate capabilities and
  are not touched here.
