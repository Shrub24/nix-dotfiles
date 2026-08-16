## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: Existing excluded source workflows remain unchanged

**Reason**: This migration-specific exclusion list names retired packages and no longer represents the repository's source ownership.
**Migration**: Keep each remaining source under its existing explicit owner; define any future updater-policy change in a separate proposal.

### Requirement: Headroom AI remains wheel-based in this migration

**Reason**: Headroom no longer uses the retired Python wheel packaging path.
**Migration**: The active Headroom runtime remains governed by the repository's OCI image policy.
