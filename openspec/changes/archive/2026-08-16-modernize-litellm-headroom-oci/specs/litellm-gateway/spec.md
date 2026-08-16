## MODIFIED Requirements

### Requirement: Gateway can enable global Headroom ASGI middleware support

The system SHALL support optional global Headroom context compression through LiteLLM's native pre-call guardrail lifecycle on hosts that enable Headroom.

#### Scenario: Global Headroom guardrail is enabled

- **WHEN** the LiteLLM module enables Headroom globally
- **THEN** the generated LiteLLM configuration SHALL register a `headroom` guardrail in `pre_call` mode
- **AND** the guardrail SHALL target the managed local Headroom proxy
- **AND** the guardrail SHALL enable compression by default without mounting Headroom ASGI middleware into the LiteLLM application

#### Scenario: Headroom is disabled

- **WHEN** `programs.litellm.headroom.enable` is false
- **THEN** the generated LiteLLM configuration SHALL omit the Headroom guardrail
- **AND** the gateway SHALL operate without a Headroom sidecar dependency

### Requirement: Gateway uses a Headroom-guardrail-capable OCI release

The system SHALL run the database-enabled LiteLLM gateway from a pinned OCI base image version that supports native Headroom guardrails.

#### Scenario: Gateway is enabled with Headroom

- **WHEN** LiteLLM and Headroom are enabled for the host
- **THEN** the managed LiteLLM image SHALL be pinned to a native-guardrail-capable release
- **AND** the image version SHALL be v1.92.0 or newer
- **AND** locally required LiteLLM compatibility patches SHALL remain applied to the derived image

### Requirement: Gateway delegates database migrations to the OCI image

The system SHALL allow the upgraded LiteLLM database OCI image to run its own tracked Prisma migration lifecycle without an additional local `prisma db push` bootstrap.

#### Scenario: Gateway starts with a database configured

- **WHEN** the LiteLLM database image starts with `DATABASE_URL` configured
- **THEN** the custom local entrypoint SHALL not run `prisma generate` or `prisma db push`
- **AND** the image's native migration lifecycle SHALL remain responsible for schema updates
