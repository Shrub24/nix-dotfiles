## ADDED Requirements

### Requirement: Secrets follow a hybrid aspect-owned ownership model

Secret declaration and template rendering SHALL follow feature ownership: a shared SOPS foundation owns the sops-nix infrastructure, a credentials aspect owns genuinely cross-feature credentials, and each service feature SHALL own its service-specific secret declarations and rendered templates.

#### Scenario: Service owns a service-specific secret

- **WHEN** a service (e.g. grist, niks3, litellm, hermes, docs-mcp) requires a secret or rendered env template
- **THEN** it SHALL declare its `sops.secrets`/`sops.templates` in its own feature module
- **AND** cross-module references SHALL use `config.sops.placeholder.X`
- **AND** there SHALL be no central module registering every consumer's templates

#### Scenario: Shared credential used across features

- **WHEN** a credential or env template is genuinely shared across features (e.g. LLM/provider API keys, `zsh-secrets.env`)
- **THEN** it SHALL live in the dedicated credentials aspect rather than being duplicated per feature

### Requirement: SOPS foundation is decoupled from application secrets

The SOPS foundation module SHALL own only the sops-nix infrastructure (module import, `sops.age.keyFile` policy, age/sops CLI safety belt) and SHALL NOT contain application secrets.

#### Scenario: Maintainer inspects the SOPS foundation

- **WHEN** a maintainer opens the sops foundation module
- **THEN** it SHALL contain no `sops.secrets`/`sops.templates` for applications
- **AND** application secrets SHALL be found in their owning feature or credentials modules
