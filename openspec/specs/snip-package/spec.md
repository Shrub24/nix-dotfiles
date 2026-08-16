<!--
canonical-spec: snip-package
status: active
source-change: archive/2026-08-09-migrate-tokf-to-snip
source-spec: openspec/changes/archive/2026-08-09-migrate-tokf-to-snip/specs/snip-package/spec.md
-->

## Purpose

Defines the canonical requirements for the snip package capability.

## Requirements

### Requirement: tokf removal from active tooling

This capability is superseded. The repository no longer ships a custom `snip` derivation; `tokf` remains absent. The standardize-dendritic-nix-architecture change removed `pkgs.snip` (local 0.18.0 superseded by nixpkgs 0.24.1). While the capability remains superseded, the agent tools package set SHALL NOT include a custom `pkgs.snip` entry and SHALL NOT include `tokf`. Reintroduce `snip` from nixpkgs only if an active consumer requires it.

#### Scenario: Agent tools package set migrated

- **WHEN** the agent tools module is enabled after the retirement
- **THEN** the package set SHALL NOT include a custom `pkgs.snip` entry and SHALL NOT include `tokf`
