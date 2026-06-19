## Why

Three package derivations in this repo — `snip`, `kreuzberg-cli`, and `headroom-ai` — still hardcode upstream version and source hash data directly in their derivations. That makes source updates repetitive and inconsistent compared with the more structured source-management patterns already present elsewhere in the repo.

Introducing `nvfetcher` for this narrow package set creates a repeatable source-update workflow without spending effort on `agentmemory` and `iii-engine`, which are expected to be retired or replaced soon.

## What Changes

- Add `nvfetcher` as a pinned flake input and expose a repo-local update path for nvfetcher-managed sources.
- Add an `nvfetcher.toml` definition covering `pkgs/snip`, `pkgs/kreuzberg-cli`, and `pkgs/headroom-ai`.
- Commit nvfetcher-generated source metadata for those packages and wire it into the flake overlay.
- Refactor `snip` and `kreuzberg-cli` so `version` and source fetch data come from generated metadata instead of inline `fetch*` definitions.
- Refactor `headroom-ai` to consume nvfetcher-managed version metadata while preserving its wheel-specific fetch construction.
- Keep `headroom-ai` wheel-based in this change; do not refactor it to sdist.
- Leave `agentmemory`, `iii-engine`, fish plugin non-flake inputs, and `hermes-agent-src` untouched.

## Capabilities

### New Capabilities
- `nvfetcher-package-sources`: The repository manages selected package source metadata through nvfetcher-generated, committed source definitions.

### Modified Capabilities
- None.

## Impact

- Affects `flake.nix`, `nvfetcher.toml`, generated source metadata, and the derivations for `snip`, `kreuzberg-cli`, and `headroom-ai`.
- Introduces a new pinned development dependency on `nvfetcher`.
- Creates a second source-update lane in the repo alongside existing flake input updates and the retained custom `agentmemory`/`iii-engine` source workflow.
