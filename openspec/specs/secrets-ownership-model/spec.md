<!--
canonical-spec: secrets-ownership-model
status: active
source-change: dendritic-cleanup-pre-nixos
-->

## Purpose

Defines the canonical requirements for how user-scoped secrets are owned and declared across the repository after the deletion of the `modules/secrets.nix` monolith: SOPS infrastructure in a foundation aspect, genuinely shared credentials in one credentials aspect, and service-specific secrets plus rendered templates in each service's own feature module.

## Requirements

### Requirement: SOPS infrastructure is owned by a dedicated foundation aspect

The repository SHALL declare SOPS infrastructure — the sops-nix module import, the age key file, and the shell-activation tooling packages (`age`, `sops`) — in exactly one foundation aspect that owns no application secrets and no rendered templates.

#### Scenario: Maintainer locates SOPS infrastructure

- **WHEN** a maintainer needs to change the SOPS module import, age key path, or tooling
- **THEN** the relevant configuration is found in the foundation aspect (`modules/security/sops.nix`)
- **AND** the foundation aspect SHALL NOT declare any `sops.secrets.*` or `sops.templates.*`

### Requirement: Shared cross-feature credentials live in one credentials aspect

Credentials that are consumed by more than one feature — the LLM/provider API keys stored in `secrets/agents.yaml` and the shell-wide `zsh-secrets.env` template — SHALL be declared together in a single shared credentials aspect (`modules/security/credentials/agents.nix`).

#### Scenario: A shared API key is added

- **WHEN** a provider key is used by multiple features
- **THEN** it SHALL be declared as a secret in the shared credentials aspect
- **AND** referenced by consumers only via `config.sops.placeholder.<NAME>`

### Requirement: Service-specific secrets and templates are owned by the service's feature module

A service's own secrets and rendered environment templates SHALL be declared in that service's feature module, colocated with the service that consumes them.

#### Scenario: A service owns its env template

- **WHEN** a service (e.g. litellm, hermes, docs-mcp, grist, niks3, aichat, nix) needs a rendered environment or access-token file
- **THEN** the `sops.secrets.<NAME>` and `sops.templates."<name>"` declarations live in that service's feature module
- **AND** the fully-merged sops config decrypts and renders the whole set once, regardless of which module declared each secret

### Requirement: Cross-module references use merged placeholders

Because sops-nix builds `config.sops.placeholder.X` from the fully-merged module config, a template in one module SHALL reference a secret declared in another module via `config.sops.placeholder.X` with no special wiring.

#### Scenario: A template references a shared credential

- **WHEN** a feature-owned template (e.g. `litellm.env`, `hermes.env`, `nix-access-tokens`) needs a value declared in the shared credentials aspect
- **THEN** the template content interpolates `config.sops.placeholder.<NAME>`
- **AND** no explicit cross-module secret-forwarding is required

### Requirement: The secrets monolith is removed

The repository SHALL NOT contain a single monolithic `modules/secrets.nix` that aggregates every application secret and template.

#### Scenario: A maintainer searches for the former monolith

- **WHEN** the repository is searched for `sops.secrets` or `sops.templates` declarations
- **THEN** declarations are found only in the foundation (none), the shared credentials aspect, and service feature modules — not in a central secrets registry
