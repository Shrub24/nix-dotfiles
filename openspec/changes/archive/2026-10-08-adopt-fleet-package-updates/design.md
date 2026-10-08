# Design

## Context

See `proposal.md` — Why. What shapes the approach is the state of the package
layer today and the mechanics of the two contracts.

**The stack being replaced.** `nvfetcher.toml` feeds a generated source set at
`pkgs/_sources/generated.{nix,json}`, which `pkgs/default.nix` imports and
injects into five packages: `pi-bolt` (the source tree), `pi-bolt-runtime` (the
AOT runtime asset), `xberg-cli`, `byterover-cli` and `codexbar`.
`pkgs/pi-plugins` imports the same generated set for one more pin (the
OmniRoute checkout) and carries 24 npm tarball pins written by hand, because
nvfetcher has no npm-tarball source type. `modules/flake/tooling.nix` puts
nvfetcher in the dev shell and publishes `apps.nvfetcher-update`; `justfile`
wraps it as `nvfetcher` and `nvfetcher-one <pkg>`. Only `pi-bolt` and
`pi-bolt-child` are `packages.<system>` outputs today (`modules/agents/pi.nix`);
the rest are overlay attributes.

**The contract.** nix-fleet at the revision this repository already locks
exposes `flakeModules.packageUpdates` (no pin bump is needed for it). It
contributes `perSystem.packageUpdates.packages` — a list of `packages.<system>`
output names — and an `update-packages` app that runs
`nix-update --flake --use-update-script --system <system> <name>` per registered
entry, from the checkout root, with `NIX_PATH` pinned to this repository's
nixpkgs and this repository's own pinned `pkgs.nix-update`. There is no flag
passthrough: `--url`, `--version=branch`, `--version-regex`,
`--override-filename` and `--subpackage` can only come from a package's
`passthru.updateScript`. It refuses an empty registry, a duplicate, an
unregistered name, a registered name that is not a package output, and a
missing nix-update — all before any updater runs. A run stops at the first
failure, propagates the child's exit code, and never commits.

**nix-update's own rules.** It locates the file it edits from
`unsafeGetAttrPos "src"` (falling back to `meta.position`) and reads release
discovery from `pkg.src.urls`, so a registered package's pin must be a literal
in its own file — a bare `fetchurl` inside a helper attrset, or a `src` passed
in from another file, cannot be patched. The update-script path additionally
builds `pkgs.mkShell { inputsFrom = [ pkg ]; }`, so a non-derivation cannot be
registered at all. It evaluates the flake from a `nix flake metadata` copy of
_tracked_ files while the script edits the live tree: modified tracked files are
visible, a newly created file is invisible until it is staged — and this
repository is jj-colocated.

**The CI contract's constraints on this shape.** It is not adopted here, but it
settles three things: acceptance is the repository's declared checks (a
hash-prefetch build is explicitly not an acceptance build); tooling is pinned
rather than resolved from a floating channel; and `packages.<system>` is the
namespace the CI artifacts are published into, so registered package names must
stay disjoint from the fleet's own outputs (`ci`, `ci-tailscale`,
`cache-api-url`, the build profiles).

## Goals / Non-Goals

**Goals:**

- Every pin this repository owns is updatable in place by one mechanism, and
  the same upstream revisions build before and after the migration.
- The package layer's shape makes a pin locatable: literal version and source,
  in the file that owns it.
- Acceptance is the canonical validation — the same check set CI will build.
- nvfetcher leaves nothing behind: no metadata, no generated set, no app, no
  dev-shell entry, no operator recipes, no live spec.

**Non-Goals:**

- The CI workflow and its provisioning; that stays in
  `settle-after-nixos-transition` and is handed the interface it needs from
  here (registered owners, canonical acceptance).
- The runtime Pi extension rows: they are app-managed in the agent directory,
  not pinned in this repository.
- The rev-pinned Neovim plugins: a rev pin needs a branch target, so they stay
  hand-pinned rather than gaining a mechanism they do not need.
- The OCI digest: the CI contract leaves image digests with renovate.
- Making the npm dependency hash refresh automatic for anyone but the owner's
  script.
- Correcting the two superseded specs that still read `status: active`
  (`snip-package`, `opencode-snip-integration`); noted, not owned here.

## Decisions

**D1. Four registered owners, one per pin set.** `pi-bolt` (source tree, AOT
runtime asset, `npmDepsHash`), `pi-plugins` (24 npm tarballs and two
branch-head checkouts, OmniRoute and fork-in), `xberg-cli`, `codexbar`. Derived
outputs stay unregistered:
`pi-bolt-child`, the compiled plugin manifests, and the model catalog that is
read out of the Pi-Bolt tree. Rejected: registering `pi-bolt` alone and letting
its script bump the plugin pins too — two unrelated upstreams under one owner,
and the plugin set refreshes on its own cadence; rejected: one registered
output per npm pin — 25 new package outputs and a forced one-pin-per-file split
for a set that is updated as a unit.

**D2. Pins are literals in the owning file.** `pkgs/_sources/` and
`nvfetcher.toml` go, and each package declares its own version and source.
Rejected: keeping the generated set and pointing the updater at it — one shared
file written by several owners breaks one-owner-per-set, and nix-update's own
documented weak spot is a file holding more than one package. For a package on
the standard path, one package per file is kept as the rule.

**D3. `pi-plugins` becomes a derivation.** It must be a registered package, and
the update-script path requires a derivation, so the recipe attrset alone is not
registrable. The pin table stays in `pkgs/pi-plugins/default.nix`; the
registered output is a derivation over that same pinned source set, carrying the
recipe attrset and the update script in `passthru`, so one file owns the pins
and one owner updates them. Rejected: moving the npm pins onto `pi-bolt` (D1).
If nothing ends up consuming the staged source set, the honest move is to fold
the owner into `pi-bolt` rather than keep a package that exists only to be
updatable — recorded as a trade-off, not settled here.

**D4. Scripts where the standard path cannot work.** The app has no flag
passthrough, so any pin needing a URL, a tag family, a branch target or a
coupled set gets a `passthru.updateScript`:

| owner        | path                | why                                                                                                                                                                                                                  |
| ------------ | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pi-bolt`    | script              | the runtime asset URL is keyed to the tag, and `version` is that tag minus its prefix; the dependency hash is refreshed by a nested `nix-update --version=skip --no-src`, the pattern nix-fleet's own `bifrost` uses |
| `pi-plugins` | script              | npm registry discovery is exact per tarball, and the OmniRoute and fork-in pins are branch heads that must fail loudly rather than resolve to a release                                                              |
| `xberg-cli`  | script              | the repository publishes per-component tags alongside release tags, so the release family must be selected explicitly                                                                                                |
| `codexbar`   | thin script wrapper | a single tag family uses standard nix-update discovery; the wrapper only adds the recorded-target input needed for deterministic acceptance                                                                          |

Rejected: forking or patching the fleet app to accept flags — the contract is
published and authoritative, and a consumer-side variant would be a second
mechanism.

The codexbar wrapper defaults to `--version=stable`, preserving standard
release discovery, and accepts `CODEXBAR_UPDATE_VERSION` for an exact
recorded-target run. This keeps it on the standard policy while allowing the
fleet app's `--use-update-script` path to satisfy D6 without command-line flag
passthrough.

**D5. Acceptance is the canonical validation, and CI-shaped.** A run edits pins
only; acceptance is `nix fmt` (no changes), `nix flake check --no-build
--no-write-lock-file`, and both NixOS configurations evaluating — the same gates
the CI contract builds on. Tooling resolves from this repository's evaluated
pins; the fleet CI workflow's own floating `nixpkgs#nix-fast-build` is its
implementation detail, not a pattern to copy.

**D6. Acceptance runs are reproducible.** Each owner's script takes a recorded
target (the `BIFROST_UPDATE_VERSION` pattern), so a re-run at an already-applied
target is provably a no-op and the acceptance run is deterministic. A script
that cannot resolve its target fails rather than reporting success.

**D7. The supersession is recorded.** The `nvfetcher-package-sources` delta
removes both requirements with a reason and a migration, and adds the
retired-state requirement; the canonical spec's front-matter status and the
INDEX row move to superseded as part of the change, so the capability keeps its
provenance instead of disappearing.

**D8. byterover is removed, not migrated.** Its consumer is being retired, so
its pin, package and formatter exclusion go first, independently of the rest.

**D9. Source URLs are templated on the version attribute.** nix-update's
rewrite is a substitution of the version inside the URL, so a version-less
literal URL cannot be retargeted: bumping `version` leaves `src` stale with no
error. CLI recipes use the modern `finalAttrs` + version-in-URL pattern, and
their acceptance is a real rewrite round-trip, not recorded-target idempotence
(which passes without ever rewriting). The same code path makes a capture group
mandatory in `--version-regex`: the extracted version is the joined groups, so
a group-less pattern filters out every tag and fails the run.

## Risks / Trade-offs

- [A pin that is not a literal in its own file cannot be located] → the
  inlining phase is a prerequisite, and each package is verified by an actual
  update run, not by inspection.
- [Tracked-only evaluation: a script that creates a file is invisible to the
  next evaluation, and jj snapshots on every command] → scripts edit existing
  files; anything new must be staged before the following evaluation, and a
  failed run leaves a partial candidate in the working-copy commit to review.
- [A script resolving a branch head or a tag family can silently pick the wrong
  revision] → OmniRoute's and fork-in's resolves fail loudly on a bad target,
  xberg-cli selects the release family explicitly, and both are checked by a
  recorded-target re-run.
- [A registered derivation that exists only to own pins is surface] → the staged
  source set is consumed by Pi-Bolt (D3).
- [Losing nvfetcher's operator ergonomics] → the app's package argument replaces
  `--filter`, and `justfile` keeps a two-recipe surface; the generated JSON and
  its recorded date are accepted losses.
- [The registry now publishes our names into `packages.<system>`] → registered
  names are ordinary package names, disjoint from the fleet CI artifacts, and a
  name registered without an output fails the app's own preflight.

## Migration Plan

Five phases, in dependency order: byterover removal; pin inlining (no revision
changes); registry and scripts; nvfetcher deletion and the recorded
supersession; acceptance. Phases two and three must leave every build producing
the same upstream content, so a revert reverts the pin _shape_, not a revision.
The mechanism is adopted only once `nix run .#update-packages` has run as a
candidate at recorded targets and the canonical validation has passed on the
result. The CI half is not part of this change: it consumes the registered
owners and the canonical acceptance from here and stays tracked in
`settle-after-nixos-transition`.
