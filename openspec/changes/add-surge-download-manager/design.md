## Context

Surge provides an upstream flake and release 0.11.2. Its flake currently hardcodes package version 0.8.5, including the Go linker version value, so using `packages.<system>.default` directly produces incorrect provenance. This repository keeps package corrections under `pkgs/` and installs TUI tools from `modules/home/dev-tools/`.

## Goals / Non-Goals

**Goals:**
- Reuse the upstream flake build while correcting its version metadata.
- Keep flake wiring and package correction separate.

**Non-Goals:**
- Configure Surge downloads, API tokens, browser extensions, or themes.
- Start `surge server` or install a system service.

## Decisions

**Pin the upstream flake at `v0.11.2`.** This preserves a reviewable source revision instead of following `main`.

**Wrap the upstream package with `overrideAttrs` under `pkgs/surge/default.nix`.** The wrapper changes only `version` and the matching Go linker flag. Copying the complete upstream Go derivation would duplicate vendor hashes and build logic; accepting version 0.8.5 would misreport provenance.

**Install Surge with the existing dev-tools package set.** It is a user-scoped TUI/CLI, not a system daemon or desktop-session component.

## Risks / Trade-offs

- **Upstream fixes its version metadata** → remove the local wrapper and consume the package directly.
- **Upstream changes linker flags** → the build/version check exposes drift; update the narrow override.
