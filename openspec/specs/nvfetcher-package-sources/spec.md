# nvfetcher-package-sources Specification

## Purpose
TBD - created by archiving change add-nvfetcher-for-packages. Update Purpose after archive.
## Requirements
### Requirement: Selected package sources are managed through nvfetcher metadata
The repository SHALL define committed nvfetcher source metadata for the selected package set consisting of `snip`, `kreuzberg-cli`, and `headroom-ai`.

#### Scenario: Maintainer inspects nvfetcher configuration
- **WHEN** a maintainer reviews the repository source-update configuration
- **THEN** the selected package set is declared in nvfetcher configuration and backed by committed generated source metadata

### Requirement: Target derivations consume generated nvfetcher metadata
The `snip` and `kreuzberg-cli` derivations SHALL consume externally generated source metadata for upstream version and source fetch information rather than hardcoding those fields inline in each derivation. The `headroom-ai` derivation SHALL consume externally generated version metadata while preserving its wheel-specific fetch construction.

#### Scenario: Maintainer updates a target package source
- **WHEN** nvfetcher-generated metadata changes for one of the selected packages
- **THEN** the corresponding derivation reads the required upstream metadata from that generated metadata path while preserving any package-specific wheel fetch mechanics

### Requirement: Existing excluded source workflows remain unchanged
The repository SHALL leave the existing source-management workflows for `agentmemory`, `iii-engine`, fish plugin non-flake inputs, and `hermes-agent-src` unchanged in this change.

#### Scenario: Maintainer reviews excluded dependencies
- **WHEN** a maintainer inspects dependencies explicitly excluded from this change
- **THEN** their current flake-input or custom source-update wiring remains intact

### Requirement: Headroom AI remains wheel-based in this migration
The `headroom-ai` package SHALL preserve its wheel-based build model while adopting nvfetcher-managed version metadata.

#### Scenario: Maintainer builds headroom-ai after migration
- **WHEN** the `headroom-ai` derivation is evaluated after nvfetcher integration
- **THEN** it still uses the wheel-based packaging path while sourcing its nvfetcher-managed version metadata from the generated metadata path

