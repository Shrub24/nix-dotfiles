## Overview

This change introduces `nvfetcher` only for the repo's remaining simple hand-pinned package sources: `snip`, `kreuzberg-cli`, and `headroom-ai`. The goal is to centralize upstream version and source-hash management while preserving each package's existing build model.

## Decisions

### Use one nvfetcher capability for three targeted packages
- The change covers only the derivations that currently hardcode a single upstream source and version inline.
- `agentmemory` and `iii-engine` remain on their existing `sources.nix` / `update.sh` path because the repo owner expects to transition away from them.

### Keep generated source metadata committed in-repo
- `nvfetcher.toml` becomes the declarative source definition.
- Generated metadata is committed so evaluation does not depend on running nvfetcher at build time.

### Preserve each package's existing build shape
- `snip` stays a `buildGoModule` package; only `version` and `src` move to generated metadata, while `vendorHash` remains manual.
- `kreuzberg-cli` stays a release-tarball derivation.
- `headroom-ai` stays wheel-based; this change does not attempt an sdist refactor.
- Because standard nvfetcher TOML cleanly tracks `headroom-ai` release version but not the exact wheel artifact shape this derivation needs, the derivation will consume nvfetcher-managed version metadata while retaining wheel-specific fetch construction.

## Wiring Approach

1. Add `nvfetcher` as a flake input pinned to `nixpkgs`.
2. Add a repo-level `nvfetcher.toml` describing the three packages.
3. Import committed generated source metadata from a single shared location.
4. Pass package-specific generated attributes into the existing overlay `callPackage` / `python3Packages.callPackage` calls.
5. Update each target derivation to accept externally supplied `version` and source data.

## Risks and Mitigations

- **Two update workflows:** nvfetcher-managed sources and flake inputs update differently. Mitigate by documenting the nvfetcher command path in the repo.
- **`headroom-ai` wheel URL fragility:** keep the current wheel model and verify builds after migration.
- **Generated file churn:** commit generated metadata and keep the scope limited to three packages.
