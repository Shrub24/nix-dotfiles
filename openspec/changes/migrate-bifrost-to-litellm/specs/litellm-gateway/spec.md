## ADDED Requirements

### Requirement: LiteLLM gateway service is declaratively managed
The system SHALL provide a Home Manager-managed LiteLLM gateway service that starts automatically for the user, reads runtime secrets from a sops-managed environment file, and renders its static proxy configuration from repo-managed Nix configuration.

#### Scenario: LiteLLM service is enabled
- **WHEN** `programs.litellm.enable` is set for the host
- **THEN** Home Manager SHALL install and manage a user service for LiteLLM
- **AND** the service SHALL read its runtime API keys from a generated environment file under the user's configuration directory
- **AND** the service SHALL consume a generated LiteLLM config file under the user's configuration directory

### Requirement: Gateway parity preserves local access contract
The system SHALL expose LiteLLM through the existing local gateway role so local tools can continue to access an OpenAI-compatible endpoint without requiring a multi-step manual bootstrap.

#### Scenario: Local client uses the gateway
- **WHEN** a local client is configured to call the declared local LiteLLM gateway endpoint
- **THEN** the client SHALL reach an OpenAI-compatible LiteLLM proxy endpoint managed by Home Manager

### Requirement: Gateway configuration changes trigger managed restarts
The system SHALL restart the LiteLLM user service when generated gateway configuration or rendered runtime secret files change.

#### Scenario: Generated config changes
- **WHEN** Home Manager updates the rendered LiteLLM config or runtime env file
- **THEN** the LiteLLM user service SHALL be restarted through Home Manager-managed service switching

### Requirement: Gateway can enable global Headroom ASGI middleware support
The system SHALL support optional global Headroom ASGI middleware enablement for the LiteLLM runtime on hosts that want gateway-wide prompt compression middleware.

#### Scenario: Global Headroom middleware is enabled
- **WHEN** the LiteLLM module enables Headroom globally
- **THEN** the LiteLLM runtime SHALL use a package environment that can import Headroom's ASGI middleware
- **AND** the LiteLLM service SHALL launch the proxy app through a wrapper that mounts `headroom.integrations.asgi.CompressionMiddleware`
