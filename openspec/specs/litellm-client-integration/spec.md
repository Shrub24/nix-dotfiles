<!--
canonical-spec: litellm-client-integration
status: active
source-change: archive/2026-06-17-migrate-bifrost-to-litellm
source-spec: openspec/changes/archive/2026-06-17-migrate-bifrost-to-litellm/specs/litellm-client-integration/spec.md
-->



## Purpose

Defines the canonical requirements for the litellm client integration capability.

## Requirements

### Requirement: OpenCode provider config targets the LiteLLM gateway
The system SHALL generate OpenCode provider configuration that targets the local LiteLLM gateway while preserving the current logical model contract required by the repo's OpenCode setup.

#### Scenario: OpenCode config is generated
- **WHEN** Home Manager renders the generated OpenCode provider overlay
- **THEN** the overlay SHALL point to the local LiteLLM gateway endpoint
- **AND** it SHALL expose the parity logical models required by the repo's OpenCode workflows
- **AND** it SHALL use LiteLLM-native downstream provider naming consistently

### Requirement: Local AI clients can be migrated to LiteLLM declaratively
The system SHALL provide declarative host-level wiring so local AI clients that currently use the Bifrost gateway can be switched to LiteLLM without imperative local edits.

#### Scenario: Host enables LiteLLM-backed clients
- **WHEN** the host configuration enables the LiteLLM migration
- **THEN** configured local AI clients such as aichat and agentmemory SHALL reference the LiteLLM gateway declaratively through Home Manager-managed configuration

### Requirement: Bifrost-specific runtime wiring is retired after parity migration
The system SHALL retire Bifrost-specific generated provider/runtime wiring once the LiteLLM parity path is in place.

#### Scenario: LiteLLM parity wiring is active
- **WHEN** LiteLLM provider and client wiring are generated for the host
- **THEN** Bifrost-specific runtime wiring SHALL no longer be required for those same local client paths
