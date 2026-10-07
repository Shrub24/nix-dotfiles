# Proposal — Adopt the fleet package-update policy in place of nvfetcher

## Why

Pins are how this repository ships software it does not write: the Pi-Bolt
release and its runtime asset, the compiled Pi plugin set, the OmniRoute
checkout, and two standalone CLIs. nvfetcher owns all of it today. nix-fleet has
since published a package-update contract and a CI contract that cover the same
ground with a smaller surface and a real acceptance path. Keeping nvfetcher
means keeping a second update engine, a generated source file that no updater
can edit in place, and a dependency hash refreshed by hand. This change moves
the pins onto the contract and retires nvfetcher.

## What Changes

- Import nix-fleet's `packageUpdates` module and register the package families
  this repository owns.
- Move every pin into the file that owns it — `version` and `src` as literals in
  each package's own derivation — replacing `nvfetcher.toml` and
  `pkgs/_sources/generated.nix`. **BREAKING** for the package layer's shape, not
  for any built output.
- Add `passthru.updateScript` for the families the standard path cannot update:
  the Pi-Bolt release (tree, runtime asset and `npmDepsHash` together), the Pi
  plugin pin set (the npm tarballs and the OmniRoute branch checkout), and
  xberg-cli (tag families). codexbar follows the standard path.
- Delete nvfetcher end to end: `nvfetcher.toml`, `pkgs/_sources/`,
  `apps.nvfetcher-update`, its devShell entry, the source-set exclusions that
  exist for it, and the `justfile` recipes.
- Remove the byterover pin along with the rest of its package.
- Supersede the `nvfetcher-package-sources` capability and declare
  `package-updates` in its place.

## Capabilities

### New Capabilities

- `package-updates`: how this repository declares the upstream pins of the
  packages it owns, updates them, and accepts the result.

### Modified Capabilities

- `nvfetcher-package-sources`: superseded — its requirements are removed and
  replaced by one requirement recording that nvfetcher is retired.

## Impact

`pkgs/default.nix`, every package under `pkgs/` that consumes a generated
source, `modules/flake/`, the devShell and app surface, `justfile`,
`openspec/specs/nvfetcher-package-sources/` and `INDEX.md`, and the pin
references in `ARCHITECTURE.md` and `context/pi-plugin-sources.md`. No host
output and no deployed behaviour changes: the same upstream revisions must build
before and after.

Two boundaries shape the work without being adopted here. The runtime Pi
extension rows are app-managed in the agent directory rather than pinned in this
repository, so they are out of scope. The CI contract is a separate follow-up,
but it constrains the shape: the update tooling resolves from this repository's
own pins rather than a floating channel, and acceptance is the same check set
that CI will build.
