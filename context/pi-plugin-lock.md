# Pi plugin lock

## The plugin lock is a standalone npm project over member manifests

**Id:** ee9a5bd7-a105-48da-80d8-96222609f8b4
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** `pkgs/pi-plugins/plugins.lock.json`, the six member manifests, and Pi-Bolt.nix `1fe822a0` (`scripts/update-plugin-lock.sh`, `nix/plugin-set.nix`, `docs/PLUGINS.md`)
**Verification:** confirmed — the lock is 87 packages with six `pbplugins/*` workspaces and no `@earendil-works/*` entries; `nix/pi-bolt.nix` stages it as its own derivation and `npm ci` accepts it
**Revisit when:** a plugin needs a closure npm cannot express (a bun or pnpm lock source keeps `nodeModules`)

A compiled plugin's npm imports must be staged at build. The set resolves through
one npm lock, `pkgs/pi-plugins/plugins.lock.json`, passed to the payload as
`pluginLock`, and installed by `nix/plugin-set.nix` as **its own derivation** —
not layered onto Pi's workspace. Pi's own tree stays where it is, so a Pi-Bolt
release bump does not invalidate the lock.

Three properties follow, and each was load-bearing in the earlier design:

- a package two plugins share is one copy;
- a plugin that needs a version a sibling pins elsewhere gets it nested under its
  own folder;
- the lock is regenerated when the **plugin set** changes, not when the release
  does.

Only plugins that declare dependencies are members: `ask-user-question`,
`herdsman`, `otel`, `permission-system`, `todo`, `tool`. A plugin without
declared dependencies needs no closure, and one that gains a dependency and is
missing from the member list fails the compile's dependency check, which names
it.

**Reason.** A range belongs next to the import that needs it, and the resolver
must be the one the ecosystem uses. Deriving the closure from each plugin's own
`package.json` removes both halves of the old failure: the pin is not written
down twice, and a mismatch is reported by resolution rather than by a bundler
that only knows a specifier.

**Rejected alternative:** one merged lock for Pi-Bolt's dependencies and the
plugins' together. It preserves Pi's pins only if each is re-pinned by hand as an
npm `override`, and it moves Pi-Bolt's own resolution into this repository.
Nesting per plugin reaches the same single-copy outcome without owning Pi's
resolution.

**Rejected alternative:** keeping `nodeModules` and adding only the build-time
range check. The check catches a wrong pin but not a plugin importing a library
it never declared.

**Consequence.** `update-plugin-lock` takes `OUT NAME=MANIFEST...` and nothing
else: it combines manifests, so it owns no source shape and a caller passes the
`package.json` it holds. `pkgs/pi-plugins/update.py` therefore regenerates the
lock in the same run that moves the pins, using each prefetched tarball's
manifest and each `manifest = "…"` path a recipe declares. Regeneration is not a
second command, because an unregenerated lock stages versions the plugins no
longer declare, which the compile refuses. `bash-processes` stays out of the
lock: its one dependency is the sibling `tool-renderer`, declared `workspace:*` —
a pnpm and bun specifier npm rejects — and the recipe's `dependencies` edge links
it into that plugin's `node_modules` instead.

## Compiled plugins resolved through Pi-Bolt's release lock

**Id:** 7d1f4a02-cd63-4a5f-9f4a-9c6c1b0e5a71
**Type:** decision
**Status:** superseded
**Superseded by:** ee9a5bd7-a105-48da-80d8-96222609f8b4
**Evidence:** confirmed

The lock was Pi-Bolt's own release lock with each plugin added as an npm
workspace, so Pi's entries arrived with the release unchanged. Upstream removed
that union: at `1fe822a0` the generator writes a standalone project, and
`docs/PLUGINS.md` states that Pi is not part of the lock. The 470-package lock
this repository carried until then was Pi's release lock plus members; the
regenerated one is 87 packages.

Two further claims in this entry are no longer true and should not be relied on:
evaluation no longer refuses a stale lock by name — the `pluginLock is stale`
message is gone, and the only evaluation-time check is `notCompiled`, a member
this package does not compile — and the lock is no longer invalidated by a
Pi-Bolt bump.
