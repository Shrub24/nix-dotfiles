<!--
canonical-spec: nvfetcher-package-sources
status: active
source-change: archive/2026-06-19-add-nvfetcher-for-packages
source-spec: openspec/changes/archive/2026-06-19-add-nvfetcher-for-packages/specs/nvfetcher-package-sources/spec.md
-->

## Purpose

Defines the canonical requirements for nvfetcher-managed package sources.

## Requirements

### Requirement: Selected package sources are managed through nvfetcher metadata

The repository SHALL define committed nvfetcher source metadata only for the active custom package set that consumes it.

#### Scenario: Maintainer inspects nvfetcher configuration

- **WHEN** a maintainer reviews the repository source-update configuration
- **THEN** every declared nvfetcher source SHALL be consumed by an active custom package
- **AND** inactive Snip and LiteLLM source records SHALL be absent

### Requirement: Target derivations consume generated nvfetcher metadata

Each package selected for nvfetcher management SHALL consume its generated upstream version and source fetch metadata rather than duplicating those fields in its derivation.

#### Scenario: Maintainer updates a target package source

- **WHEN** nvfetcher-generated metadata changes for an active selected package
- **THEN** the corresponding derivation SHALL consume the updated generated fields
