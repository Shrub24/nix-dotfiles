# Pi plugin dependencies

## A plugin's npm dependencies are pinned by its consumer, so the producer cannot enforce them

**Id:** 810ac3c5-0a8e-4535-8c7d-46de9b84df10
**Type:** issue
**Status:** superseded
**Superseded by:** [pi-plugin-lock.md](pi-plugin-lock.md) — Pi-Bolt derives each plugin's declared dependencies from its own `package.json` and the plugin set resolves through one lock, so the consumer no longer pins them by hand
**Evidence:** contradicted
**Source:** a failing `nix build .#packages.x86_64-linux.pi-bolt` on this host, the two plugin definitions (`pi-extensions/nix/plugins.nix`, `pkgs/pi-plugins/default.nix`), the published `pi-radar` export maps, and `pi-bolt/nix/plugins/build-plugin.nix`
**Verification:** corroborated for the failure, contradicted for the conclusion — the failure reproduced at `pi-radar` 0.2.0 and cleared at 0.5.1 with no other change, and `pi-radar@0.2.0` exports no `./communication` while `0.5.1` does; but Pi-Bolt 0.9.6 now reads each plugin's `package.json`, resolves the set through a lock, and fails the compile on an out-of-range pin, so the consumer no longer has to write the pin down
**Revisit when:** this repository consumes `pi-extensions`' plugin outputs by name _(met — see “Taken up” below)_, or Pi-Bolt's builder derives a plugin's dependencies itself

_Kept for the incident. The map it describes no longer exists; see
[pi-plugin-lock.md](pi-plugin-lock.md)._

The compiled payload's `installPhase` failed with
`Could not resolve: "pi-radar/communication"` at
`pi-herdsman/extension/index.ts:19`. A plugin's `node_modules` is assembled from
this repository's central `libraries` map in `pkgs/pi-plugins/default.nix`,
where `pi-radar` was pinned at 0.2.0; the pinned `pi-extensions` revision
imports `pi-radar/communication`, an export that first appears in 0.3.0. Moving
that one entry to 0.5.1 builds.

**Two definitions.** `pi-extensions` already builds each plugin with
`buildPiBoltPlugin` and pins its libraries beside the source that needs them
(`nix/plugins.nix`, exported as `overlays.default`,
`packages.<system>.extensions.plugins`, `pluginTrees` and `compiledCheck`). This
repository ignores those: `_pi-extensions.nix` names roles and sources,
`pkgs/pi-plugins/default.nix` re-declares every recipe
(`checkout = name: "${piExtensions}/${name}"`, `entry`, `dependencies`, `patch`)
with its own `libraries` map, and builds its own `pi-bolt.override`. The copy
that runs is this repository's, it knows nothing of the producer's pins, and
nothing compares them. `pi-extensions`' own `nix/plugins.nix` also said 0.2.0,
so the producer copy rots the same way — the problem is not which copy is
authoritative but that the pin is written down twice, away from the import.

**What the map cannot express.** It is keyed by npm name globally and merged
into every plugin (`nodeModules = "${libraryNodeModules}/node_modules"` in
`toPlugin`), so a plugin silently receives libraries it never declared and no
derivation records a plugin's real dependency set. Nothing checks that a pinned
version satisfies the source pinned beside it, so a mismatch surfaces as a
bundler error naming the consumer's node_modules.

**Missing in Pi-Bolt's plugin builder** (`nix/plugins/build-plugin.nix`):

- No dependency closure derived from the plugin's own `package.json` or
  lockfile; `libraries` is supplied by the caller. The one lockfile-driven case
  is hand-built — pi-extensions' `otelDependencies` filters dev and Pi-provided
  peer entries and passes `--legacy-peer-deps` to `importNpmLock.buildNodeModules`.
- No per-plugin default for `nodeModules`, so libraries are not scoped to the
  plugin that needs them.
- No resolution assertion after staging. Checking that every bare specifier and
  subpath a plugin imports resolves inside its node_modules would turn this
  failure into "herdsman imports `pi-radar/communication` but `pi-radar@0.2.0`
  is staged", instead of a bundler hint.
- No way to consume a producer flake's already-built plugin: `dependencies` links
  plugins by `packageName`, but their npm libraries must be re-pinned by each
  consumer.

**Shape that removes the class.** `pi-extensions` stays the producer and this
repository takes `inputs.pi-extensions.overlays.default` — or
`packages.<system>.extensions.plugins` — and refers to plugins by name, deleting
the recipes and the `libraries` map. The pin then moves only where the import
moves. Verifying a plugin's imports during its build would close the remaining
gap for any producer.

## Taken up

`pkgs/pi-plugins/default.nix` now takes the producer's nine plugins from
`inputs.pi-extensions.packages.<system>.<id>` and names them only in
`upstreamOwned`; the consumer's `libraries` map is gone, and `radar`'s and
`herdsman`'s derivations are the producer's own (`drvPath` equality verified).
Recipes remain here for third-party plugins no producer owns — tarballs such as
`rewind`, `recap` and `anthropic-auth`, and checkouts such as `omniroute` and
`fork-in`. `pi-extensions/nix/recipes.nix` is still read for the _lock
candidates_ of the producer's plugins, because their manifests are what the
plugin lock names, but nothing here builds them from those recipes any more.

The npm helper injection this repository carried (`pkgs/fetch-npm-package.nix`,
an `overrideScope` on `piBoltPlugins`) is deleted: the helper is in the
producer's scope since `pi-bolt-nix` `15b6eee4`, so the scope here is Pi-Bolt's
own and the plugins come from the package table.

## A runtime-loading row names the built plugin, not the checkout

**Id:** 2b90bc1a-0795-40a1-b6e7-2fa2280b7e0e
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** the two trees, resolved with node under the ESM `import` condition
**Revisit when:** Pi starts installing dependencies for a local package it loads

Stock Pi loads an extension from the path a row names, and installs nothing for
a local path — `getInstalledPath` resolves it and uses the directory as it is.
A checkout in the store therefore has no `node_modules`, and an extension that
declares npm dependencies cannot resolve them from where it sits. The built
plugin tree can: `buildPiBoltPlugin` copies the source, stages the plugin's own
closure into `$out/node_modules`, and links each plugin dependency there by
`packageName`. Four rows (`otel`, `herdsman`, `bash-processes`, `tool-renderer`)
name `@recipe@<id>` for that reason; the rows whose plugins declare no
dependencies keep `@extensions@/<dir>`, where the two are the same tree.

This replaced `pkgs/pi-otel`, which existed only because `otel` was the one row
that needed a staged closure before the producer published one per plugin.

**Alternative:** keep every row on the checkout and give each plugin a
`node_modules` of its own somewhere else. That is what `pkgs/pi-otel` did for
one plugin — a package per plugin, in each consumer, for a tree the producer
already builds.

**Known gap:** `tool-renderer` declares `diff` but its recipe stages no
`nodeModules`, so its built tree has none either. Bun resolves `diff` from its
own install cache by accident; node does not. The fix belongs in the producer's
recipe.
