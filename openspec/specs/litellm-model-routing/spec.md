<!--
canonical-spec: litellm-model-routing
status: active
source-change: archive/2026-06-17-migrate-bifrost-to-litellm
source-spec: openspec/changes/archive/2026-06-17-migrate-bifrost-to-litellm/specs/litellm-model-routing/spec.md
-->

## Purpose

Defines the canonical requirements for the litellm model routing capability.

## Requirements

### Requirement: Existing logical model aliases are preserved at parity

The system SHALL preserve the current logical model aliases used by local clients during the phase-1 migration from Bifrost to LiteLLM.

#### Scenario: Client requests a parity alias

- **WHEN** a client requests one of the current logical aliases (`coder`, `main`, `summariser`, `budget`, `explorer`, or `embedding`)
- **THEN** LiteLLM SHALL expose that alias as a valid model entry

### Requirement: Alias routing preserves current primary targets and fallbacks

The system SHALL generate LiteLLM routing configuration that preserves the current provider/model intent and fallback ordering encoded in the repo's LiteLLM-native alias/deployment source of truth.

#### Scenario: Primary route is available

- **WHEN** a parity alias is requested and its primary deployment is healthy
- **THEN** LiteLLM SHALL route the request to the configured primary provider/model for that alias

#### Scenario: Primary route is unavailable

- **WHEN** a parity alias is requested and its primary deployment fails in a way covered by LiteLLM fallback behavior
- **THEN** LiteLLM SHALL use the configured fallback deployment for that alias

### Requirement: Generated deployments use explicit LiteLLM provider semantics

The system SHALL generate LiteLLM deployments using provider-qualified model definitions that LiteLLM can classify without relying on Bifrost-specific provider names or implicit provider inference.

#### Scenario: Generated config contains an OpenAI-compatible upstream

- **WHEN** the generated LiteLLM config targets a custom OpenAI-compatible upstream endpoint
- **THEN** the deployment SHALL use an explicit LiteLLM-compatible provider form such as `openai/<model>` together with the configured `api_base` and `api_key`
- **AND** the generated config SHALL NOT depend on custom provider names like `crof` or `opencode_go` being understood by LiteLLM

### Requirement: Phase-1 routing uses built-in LiteLLM policy only

The system SHALL achieve parity routing without requiring custom Python routing hooks, Redis-backed state, or quota-aware routing policy in this change.

#### Scenario: Phase-1 gateway is enabled

- **WHEN** the parity LiteLLM migration is applied
- **THEN** the generated LiteLLM routing config SHALL rely only on built-in LiteLLM routing and fallback features
