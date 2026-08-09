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

### Requirement: Headroom receives authoritative context limits
The system SHALL generate Headroom's model context-limit catalog from the LiteLLM route registry metadata selected by OpenCode client models.

#### Scenario: A LiteLLM model alias is compressed
- **WHEN** Headroom receives a compression request for a configured LiteLLM model alias
- **THEN** its generated catalog SHALL provide that alias's context limit
- **AND** the catalog SHALL omit provider pricing that is not declared in the source metadata

### Requirement: LiteLLM route metadata is canonical
Each LiteLLM route SHALL declare one explicit models.dev registry identifier. A string fallback-chain entry SHALL target the route's logical model identifier; a structured entry SHALL remain available when an upstream target differs.

#### Scenario: A route uses standard provider targets
- **WHEN** a route has string upstream entries in its fallback chain
- **THEN** generated LiteLLM deployments SHALL target the route key for each such entry
- **AND** client model metadata SHALL resolve from that route's registry identifier

#### Scenario: A route uses a provider-specific target name
- **WHEN** a fallback-chain entry declares an explicit target model
- **THEN** generated LiteLLM deployments SHALL use that explicit target rather than the route key

### Requirement: The managed Headroom CLI selects lean-ctx for wrapping
The system SHALL select `lean-ctx` when the managed Headroom CLI is used for an explicit `headroom wrap` command.

#### Scenario: An operator invokes the wrapper command
- **WHEN** an operator invokes `headroom wrap ...` through the managed CLI wrapper
- **THEN** the wrapper SHALL set `HEADROOM_CONTEXT_TOOL=lean-ctx`
- **AND** it SHALL continue to use the managed Headroom container
