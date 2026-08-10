<!--
canonical-spec: snip-package
status: active
source-change: archive/2026-08-09-migrate-tokf-to-snip
source-spec: openspec/changes/archive/2026-08-09-migrate-tokf-to-snip/specs/snip-package/spec.md
-->



## Purpose

Defines the canonical requirements for the snip package capability.

## Requirements

### Requirement: Pinned snip derivation
The system SHALL provide a custom `snip` derivation pinned to an explicit upstream release of `github.com/edouard-claude/snip`.

#### Scenario: Build snip from pinned source
- **WHEN** the Home Manager configuration is evaluated or built
- **THEN** the `snip` package SHALL resolve from the repo's custom package overlay rather than relying on an ambient system install

### Requirement: snip CLI exposure
The system SHALL expose the `snip` CLI through the Home Manager agent tools bundle.

#### Scenario: Agent tools enabled
- **WHEN** `programs.agentTools.enable = true`
- **THEN** `snip` SHALL be present in `home.packages`

### Requirement: tokf removal from active tooling
The system SHALL stop installing `tokf` as part of the active agent tools package set.

#### Scenario: Agent tools package set migrated
- **WHEN** the agent tools module is enabled after the migration
- **THEN** the package set SHALL include `snip` and SHALL NOT include `tokf`

### Requirement: Direct CLI verification
The `snip` derivation SHALL expose a runnable `snip` binary.

#### Scenario: CLI help works
- **WHEN** `snip --help` or `snip --version` is run from the built environment
- **THEN** the binary SHALL execute successfully
