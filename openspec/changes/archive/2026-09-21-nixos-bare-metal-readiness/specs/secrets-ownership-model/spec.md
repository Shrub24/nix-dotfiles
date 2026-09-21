# secrets-ownership-model

## Purpose

Extends service-feature secret ownership to root-owned system-scoped secrets on the NixOS target: the Niks3 upload credential is declared by the Niks3 feature module, decrypted to a root-owned path, and never exposed.

## MODIFIED Requirements

### Requirement: Service-specific secrets and templates are owned by the service's feature module

A service's own secrets and rendered environment templates SHALL be declared in that service's feature module, colocated with the service that consumes them.

#### Scenario: A service owns its env template

- **WHEN** a service needs a secret file or a rendered environment derived from secrets
- **THEN** the `sops.secrets.<NAME>` declaration and any required `sops.templates."<name>"` declaration live in that service's feature module
- **AND** the fully-merged sops config decrypts and, when required, renders the whole set once, regardless of which module declared each secret

#### Scenario: A system-scoped service secret is root-owned

- **WHEN** a service feature module declares an upload credential for the NixOS target (e.g. Niks3's auth token)
- **THEN** the secret is declared in that feature module at system scope, decrypted to a root-owned path, and referenced directly by the consuming service
- **AND** the secret value SHALL NOT be exposed in the repository, the Nix store, or user scope
