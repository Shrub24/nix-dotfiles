## ADDED Requirements

### Requirement: Headroom proxy provides code-aware context compression
The system SHALL run a Home Manager-managed Headroom proxy from a pinned official code-aware OCI image when Headroom is enabled.

#### Scenario: Host enables Headroom
- **WHEN** `programs.litellm.headroom.enable` is set
- **THEN** Home Manager SHALL manage a local Headroom proxy service
- **AND** the service SHALL use a pinned image that includes proxy and code-compression capabilities
- **AND** the proxy SHALL persist its Headroom state outside the container lifecycle

### Requirement: Headroom proxy exposes shared retrieval tools
The system SHALL expose the enabled Headroom proxy's streamable HTTP MCP endpoint to local clients so compressed originals can be retrieved through the same compression store.

#### Scenario: A client retrieves guarded content
- **WHEN** a client calls the Headroom MCP retrieval tool with a valid compression hash produced by the proxy
- **THEN** the service SHALL return the corresponding original content while it remains within Headroom's retention policy

### Requirement: Headroom operational CLI is available declaratively
The system SHALL provide a host command for supported Headroom operational commands that delegates to the managed Headroom container rather than creating a second mutable runtime.

#### Scenario: User runs a Headroom learning command
- **WHEN** the managed Headroom service is running and the user invokes `headroom learn`
- **THEN** the command SHALL execute against the managed container and its persistent Headroom state
