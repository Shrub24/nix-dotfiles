## Purpose

Preserves a small, stable Pi package and settings integration that can be re-enabled later without retaining obsolete extension-era configuration.

## ADDED Requirements

### Requirement: Pi is disabled without runtime residue

The Pi integration SHALL be disabled by default for the Arch host while retaining only the configuration needed for future declarative enablement.

#### Scenario: Pi remains disabled

- **WHEN** the Arch Home Manager configuration is applied with Pi disabled
- **THEN** Pi SHALL install no package or runtime configuration
- **AND** Pi-specific activation hooks and secrets SHALL NOT be present

### Requirement: Pi package and settings are declarative

The Pi integration SHALL accept a package and freeform settings and SHALL render the supported settings file when enabled.

#### Scenario: Pi is re-enabled

- **WHEN** a host enables Pi and supplies a package and settings
- **THEN** Home Manager SHALL install the selected package
- **AND** it SHALL render those settings under Pi's managed configuration directory

### Requirement: Pi does not encode extension-specific schemas

The retained Pi integration SHALL NOT define repository-owned schemas for permissions, MCP adapters, search backends, subagents, Telegram, or version-specific extension packages.

#### Scenario: Upstream Pi extensions change

- **WHEN** a future Pi version changes its extension APIs
- **THEN** the disabled repository skeleton SHALL require no migration until that integration is deliberately reintroduced
