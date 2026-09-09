# Tasks — migrate Herdr and Pi configuration into Nix

## 1. Herdr module migration

- [x] 1.1 Rewrite `modules/agents/herdr.nix` to set `programs.herdr.settings` from the live `config.toml` contents, retaining the `llm-agents` package override and deleting the `xdg.configFile."herdr"` symlink stanza

  - refs: `modules/agents/herdr.nix`, `~/.dotfiles/apps/herdr/config.toml`
  - criteria: module publishes `flake.modules.homeManager.herdr` with `programs.herdr.package` from `inputs.llm-agents` and a `settings` attrset whose rendered TOML matches the live file, including the `ui.sidebar.agents.rows` value Herdr persisted at runtime; no `mkOutOfStoreSymlink` remains in the file.
  - verify: done — `nix build` of the rendered file then a `tomllib` comparison against the live `config.toml` reports EQUAL. `nix flake check --no-build` passes.

## 2. Pi module migration

- [x] 2.1 Rewrite `modules/agents/pi.nix` to render `programs.pi-coding-agent.settings` inline from the live `settings.json`, keeping the existing package override untouched

  - refs: `modules/agents/pi.nix`, `~/.dotfiles/apps/pi/settings.json`
  - criteria: every `settings.json` key is carried over except `lastChangelogVersion` and `subagents.agentOverrides` (already removed); `subagents.defaultExtensions = [ ]` and `subagents.defaultProvider = "omniroute"` are carried over; the relative `pi-subagents` package source becomes absolute because it points outside the repository.
  - verify: done — rendered settings build and a JSON comparison against the live file reports EQUAL apart from the intentional absolute `pi-subagents` path. `nix flake check --no-build` passes.

- [x] 2.2 Add `home.file` entries in `modules/agents/pi.nix` for `mcp.json`, `pi-fff.json`, `pi-starship.toml`, `pi-auto-permissions/config.json`, `extensions/subagent/config.json`, the `extensions/omniroute` symlink, and the `agents` directory

  - refs: `modules/agents/pi.nix`, `~/.dotfiles/apps/pi/mcp.json`, `~/.dotfiles/apps/pi/pi-fff.json`, `~/.dotfiles/apps/pi/pi-starship.toml`, `~/.dotfiles/apps/pi/pi-auto-permissions/config.json`, `~/.dotfiles/apps/pi/extensions/pi-subagents/config.json`
  - criteria: each file is rendered from an inline Nix value; `pi-starship.toml` stays a real TOML file under `modules/agents/pi/` and is mounted by `source`; `home.file.".pi/agent/agents".source = ./pi/agents` mounts the subagent definitions as one store-backed directory; the `extensions/omniroute` entry is an out-of-store symlink to the worktree path; the `home.file.".pi/agent"` symlink stanza is deleted. The unread `extensions/pi-subagents/config.json` is relocated to `extensions/subagent/config.json`, the path pi-subagents actually resolves. `pi-tool.json`, `pi-stamp.json`, `pi-herdr.json`, and `extensions/pi-tool-display/config.json` are deliberately not declared — see the boundary section in `design.md`.
  - verify: done — `home.file` exposes `.pi/agent/{mcp.json,pi-fff.json,pi-starship.toml,agents}`, `.pi/agent/pi-auto-permissions/config.json`, `.pi/agent/extensions/subagent/config.json`, `.pi/agent/extensions/omniroute`, and the absolute `/home/saurabhj/.pi/agent/settings.json`; the whole-directory `.pi/agent` entry is gone. `nix flake check --no-build` passes.

## 3. Pi subagent definitions

- [x] 3.1 Land the seven definitions as repository prompt text and get Pi out of the shared agent directory

  - refs: `modules/agents/pi/agents/{scout,worker,reviewer,researcher,oracle,delegate,evidence-auditor}.md`, `modules/flake/tooling.nix`
  - criteria: the files live under `modules/agents/pi/agents/`; `modules/agents/pi/agents/**` is added to the treefmt `settings.global.excludes`; the ejected copies are deleted from `~/.agents`, leaving only `skills/` and `.skill-lock.json` there.
  - verify: `nix fmt -- modules/agents/pi` traverses 7 files and emits 0; each file is byte-identical to its ejected source; `find modules/agents/pi -name '*.nix'` is empty so `import-tree` gains no module.

- [x] 3.2 Port every `subagents.agentOverrides` value into the matching definition's frontmatter

  - refs: `modules/agents/pi/agents/*.md`, `~/.dotfiles/apps/pi/settings.json`
  - criteria: for each of the seven agents, `model`, `thinking`, and `tools` come from the removed overrides rather than the bundled defaults; `extensions: [ ]` and `allowNestedSubagents: false` are dropped (`defaultExtensions` in settings covers the first, the second was a no-op); `advertise: true`, `fallbackModels`, and `completionGuard: false` on the read-only roles are added; `delegate` gets `acceptanceRole: writer` and `evidence-auditor` `acceptanceRole: read-only`; `mcp__<server>` entries become `mcp:<server>` selectors, with `docs-mcp-server` narrowed to its six non-mutating tools where the agent has no write tool. Prompt bodies are preserved byte-for-byte.
  - verify: done — all seven list as user agents with `omniroute/`-prefixed models and the intended thinking levels; `get reviewer` reports `Completion guard: false`, `Extensions: (none)`, and resolved absolute subagent-only extension paths.

- [x] 3.3 Remove `subagents.agentOverrides` from the live settings and add the settings-level defaults

  - refs: `~/.dotfiles/apps/pi/settings.json`
  - criteria: `subagents` contains no `agentOverrides`; it sets `defaultExtensions = [ ]` and `defaultProvider = "omniroute"`. Ordering matters: the definitions in 3.1–3.2 must be discoverable first, because overrides outrank frontmatter and removing them alone would strip every agent to its bundled tool list.
  - verify: done — `subagent({ action: "list", capabilities: true })` shows the same per-agent models, thinking levels, and tool sets as before the port, now sourced from frontmatter.

- [x] 3.4 Expose the repository definitions to the running Pi without waiting for the migration switch

  - refs: `~/.dotfiles/apps/pi/agents` (temporary symlink to `modules/agents/pi/agents`)
  - criteria: a single directory symlink so one copy of the definitions serves both the running Pi and the repository; it is explicitly temporary and is deleted at deploy.
  - verify: `ls ~/.pi/agent/agents` lists the seven definitions; `subagent({ action: "get", agent: "reviewer" })` resolves them from the Pi agent directory.

## 4. Spec bookkeeping

- [x] 4.1 Delete `openspec/changes/add-herdr-pi-native/` as superseded

  - refs: `openspec/changes/add-herdr-pi-native/`
  - criteria: the directory is removed; its implemented module swap is already in the tree; its unsynced delta filed Herdr requirements under `pi-agent-skeleton`, which this change removes.
  - verify: done — removed; the only remaining references are this change's own proposal, design, and task text. `openspec validate --strict migrate-agent-configs-to-nix` passes.

- [x] 4.2 Record the boundary decision in `ARCHITECTURE.md`

  - refs: `ARCHITECTURE.md`
  - criteria: durable-decisions rows state which Herdr and Pi files are Nix-owned and which remain application-owned, with the rewrite-file rule as the boundary and the `rename()` hazard called out; a second row records that Pi agent definitions live under the Pi agent directory rather than `~/.agents`.
  - verify: done — `nix fmt` reports no change to the edited Markdown.

- [ ] 4.3 Validate planning artifacts: `nix fmt`, `nix flake check --no-build --no-write-lock-file`, `openspec validate --strict migrate-agent-configs-to-nix`

  - criteria: statix/deadnix checks pass over the new change and the treefmt exclusion; strict OpenSpec validation passes.
  - verify: all three commands exit zero.

## 5. Deploy (explicit user approval required before starting)

Run this from a plain terminal, not from inside a Pi session: it moves Pi's own
config directory. Steps 5.1–5.5 are the dark window; the rest is verification.

**Ordering constraint that drives the whole sequence.** `~/.pi/agent` and
`~/.config/herdr` are currently Home Manager link-farm symlinks whose targets
live in `/nix/store`. Once the modules declare files *inside* those
directories, activation has to create them — writing through a store symlink
fails with `EACCES`, and creating a file where a foreign symlink already exists
is refused rather than clobbered. So the old symlinks must be gone **before**
the switch, and every path Nix is about to own must be gone with them.

- [ ] 5.0 Build the activation package **before** the dark window, so a build failure cannot leave the directories half-moved

  ```sh
  cd ~/.dotfiles/nix
  nh home build -c saurabhj
  ```

  - criteria: no commit is needed — staged files are tracked, so the flake sees them. The build only produces store paths; it does not touch `~/.pi/agent` or `~/.config/herdr`, so it is safe to run while the old symlinks are still in place.
  - verify: the build exits zero and prints a store path.

- [ ] 5.0b Stop Herdr and confirm nothing is holding the directories

  ```sh
  herdr server stop
  pgrep -a pi                                  # expect no output
  ls ~/.dotfiles/apps/herdr/*.sock 2>&1        # expect "No such file"
  ```

- [ ] 5.1 Confirm both top-level paths are the HM link-farm symlinks and record their sizes

  - verify: `readlink ~/.pi/agent ~/.config/herdr` prints `/nix/store/*-home-manager-files/...` for both; `du -sh ~/.dotfiles/apps/pi ~/.dotfiles/apps/herdr`

- [ ] 5.2 Remove the two symlinks with `unlink` (never `rm -rf`), then move the real directories into place

  ```sh
  unlink ~/.pi/agent
  unlink ~/.config/herdr
  mv ~/.dotfiles/apps/pi    ~/.pi/agent
  mv ~/.dotfiles/apps/herdr ~/.config/herdr
  ```

  - criteria: `unlink` removes only the symlink; both `mv` calls are renames within one filesystem, so ~1.1 GB moves instantly and no copy is made. `mv` also removes the now-empty `../apps` entries, so there is nothing left to `rmdir` afterwards.
  - verify: `[ -L ~/.pi/agent ] || [ -L ~/.config/herdr ]` prints nothing; `ls ~/.pi/agent` shows `npm`, `sessions`, `git`, and the rest; `ls ~/.config/herdr` shows `plugins/` and `plugins.json`.

- [ ] 5.3 Delete every path Nix is about to own

  ```sh
  rm ~/.config/herdr/config.toml

  rm ~/.pi/agent/settings.json ~/.pi/agent/mcp.json \
     ~/.pi/agent/pi-fff.json ~/.pi/agent/pi-starship.toml
  rm -rf ~/.pi/agent/pi-auto-permissions   # only holds the Nix-owned config.json
  rm -rf ~/.pi/agent/extensions/pi-subagents  # unread; Nix writes extensions/subagent/
  rm ~/.pi/agent/extensions/omniroute     # symlink into the OmniRoute worktree
  rm ~/.pi/agent/agents                   # temporary dev symlink from task 3.4
  mv ~/.pi/agent/settings.json.bak-* /tmp/  # pre-port backup; delete once verified
  ```

  - criteria: `rm` on `extensions/omniroute` and `agents` removes symlinks only, so neither takes `-r`. These paths are **not** touched, because Nix does not own them and deleting them would lose the values:
    - `~/.pi/agent/pi-tool.json`, `~/.pi/agent/pi-stamp.json`, `~/.pi/agent/extensions/pi-tool-display/config.json` — application-owned, self-written
    - `npm/`, `git/`, `sessions/`, `fff/`, `missions/`, `intercom/`, `auth.json`, `trust.json`
    - on the Herdr side: `plugins/`, `plugins.json`, `session.json`, `release-notes.json`, `.plugins.lock`, logs, sockets
  - verify: `ls ~/.pi/agent` shows no config JSON and no `agents`; `ls ~/.pi/agent/extensions` shows `omniroute` gone.

- [ ] 5.4 Switch

  ```sh
  cd ~/.dotfiles/nix
  nh home switch -c saurabhj
  ```

  - criteria: activation succeeds with no "existing file would be clobbered" error and no write into a store path.

- [ ] 5.5 Verify the rendered configuration is store-backed, the directories are real, and Herdr does not replace its own config symlink

  ```sh
  readlink ~/.pi/agent/settings.json ~/.pi/agent/agents ~/.config/herdr/config.toml
  for p in ~/.pi/agent ~/.config/herdr; do [ -L "$p" ] && echo "FAIL: $p is still a symlink"; done; echo "done"
  ```

  - criteria: each `readlink` prints a `/nix/store/...` path, and the loop prints only `done`.
  - verify: `pi` starts and `subagent({ action: "list", capabilities: true })` reports the seven user agents; `herdr status` reports the 12 plugins.
  - verify (Herdr write hazard): change one persisted setting in the Herdr UI, then re-run `readlink ~/.config/herdr/config.toml`. It must still print the store path. If it prints nothing — a real file — Herdr replaces the symlink by rename, and `herdr/config.toml` has to move to the application-owned column with `programs.herdr.settings` dropped.

- [ ] 5.6 Delete the temporary backup

  - criteria: `/tmp/settings.json.bak-*` removed once 5.5 passes.

### Rollback

```sh
mv ~/.pi/agent ~/.dotfiles/apps/pi
mv ~/.config/herdr ~/.dotfiles/apps/herdr
cd ~/.dotfiles/nix && git revert <deploy-commit>   # or restore the two mkOutOfStoreSymlink stanzas
nh home switch -c saurabhj
```

No state is rewritten by this change: Pi and Herdr read the same directory paths
before and after, so `npm/`, `plugins/`, `sessions/`, and `trust.json` carry over
untouched. `nh home rollback` alone is not sufficient, because it restores the
old generation while the directories are still at their new paths.
