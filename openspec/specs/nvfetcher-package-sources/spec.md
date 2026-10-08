<!--
canonical-spec: nvfetcher-package-sources
status: superseded
source-change: archive/2026-06-19-add-nvfetcher-for-packages
source-spec: openspec/changes/archive/2026-06-19-add-nvfetcher-for-packages/specs/nvfetcher-package-sources/spec.md
-->

## Purpose

Defines the canonical requirements for nvfetcher-managed package sources.

## Requirements

### Requirement: nvfetcher is retired

This capability is superseded. The repository no longer carries nvfetcher configuration, a generated source set, or an nvfetcher update app; every package pin is declared by the package that owns it and updated through the package-update contract. While the capability remains superseded, the repository SHALL NOT add nvfetcher metadata, a generated source set, or a second pin-update path.

#### Scenario: Repository is inspected after the transition

- **WHEN** the package layer is inspected after the transition
- **THEN** no nvfetcher configuration, generated source set or nvfetcher update app exists
