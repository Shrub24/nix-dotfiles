<!--
canonical-spec: opencode-snip-integration
status: active
source-change: archive/2026-08-09-migrate-tokf-to-snip
source-spec: openspec/changes/archive/2026-08-09-migrate-tokf-to-snip/specs/opencode-snip-integration/spec.md
-->

## Purpose

Defines the canonical requirements for the opencode snip integration capability.

## Requirements

### Requirement: OpenCode plugin registration

This capability is superseded. The repository no longer ships the `snip` CLI or registers the `opencode-snip` plugin; the standardize-dendritic-nix-architecture change retired both. While the capability remains superseded, the managed OpenCode plugin list SHALL NOT include `opencode-snip`. Reintroduce from nixpkgs together if filtering is wanted again.

#### Scenario: OpenCode config rendered

- **WHEN** the managed OpenCode configuration is materialized
- **THEN** the plugin list SHALL NOT include `opencode-snip` while the capability remains superseded
