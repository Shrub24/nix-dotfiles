# Pi plugin lock

## The plugin lock is a standalone npm project over member manifests

**Id:** ee9a5bd7-a105-48da-80d8-96222609f8b4
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** `pkgs/pi-plugins/plugins.lock.json`, the six member manifests, and Pi-Bolt.nix `1fe822a0` (`scripts/update-plugin-lock.sh`, `nix/plugin-set.nix`, `docs/PLUGINS.md`)
**Verification:** confirmed — the lock is 90 packages with seven `pbplugins/*` workspaces and no `@earendil-works/*` entries; `nix/pi-bolt.nix` stages it as its own derivation and `npm ci` accepts it
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

Membership follows the manifest: a plugin whose `package.json` declares
`dependencies` is a member. The updater reads each candidate's manifest to decide,
so a plugin that gains a dependency joins the lock on the next regeneration. Every
candidate's manifest defaults to its own `package.json`: a checkout's at its
checkout path, an npm tarball's at `package/package.json` inside the archive.
`omniroute`, `fork-in` and `powerline-footer` are not candidates, so a dependency
they gain must be added by hand; the compile's dependency check names it.

The nine plugins `pi-extensions` publishes are candidates through its
`lib.pluginLockCandidates` output — its manifests and its `pi-radar` pin, taken as
data rather than read out of its `nix/recipes.nix`, which this repository no longer
imports. Its plugin *builds* come from its package table for the same reason: the
producer owns a plugin's pins and its build identity, and this repository names
which of them it uses.

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
lock in the same run that moves the pins, reading each candidate's manifest from
its source. Regeneration is not a
second command, because an unregenerated lock stages versions the plugins no
longer declare, which the compile refuses. `bash-processes` stays out of the
lock because its manifest declares no npm dependencies; its sibling
`tool-renderer` reaches it through the recipe's `dependencies` edge.

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
