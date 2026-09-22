<!--
canonical-spec: secrets-ownership-model
status: active
source-change: dendritic-cleanup-pre-nixos
-->

## Purpose

Defines the canonical requirements for how user-scoped secrets are owned and declared across the repository after the deletion of the `modules/secrets.nix` monolith: SOPS infrastructure in a foundation aspect, genuinely shared credentials in one credentials aspect split into one secret file per consumer group, and service-specific secrets plus rendered templates in each service's own feature module.

## Requirements

### Requirement: SOPS infrastructure is owned by a dedicated foundation aspect

The repository SHALL declare SOPS infrastructure — the sops-nix module import, the age key file, and the shell-activation tooling packages (`age`, `sops`) — in exactly one foundation aspect that owns no application secrets and no rendered templates.

#### Scenario: Maintainer locates SOPS infrastructure

- **WHEN** a maintainer needs to change the SOPS module import, age key path, or tooling
- **THEN** the relevant configuration is found in the foundation aspect (`modules/security/sops.nix`)
- **AND** the foundation aspect SHALL NOT declare any `sops.secrets.*` or `sops.templates.*`

### Requirement: Shared cross-feature credentials live in one credentials aspect

Credentials consumed by more than one feature SHALL be declared together in a single shared credentials aspect (`modules/security/credentials.nix`), and SHALL be stored in one encrypted file per consumer group — `secrets/llm-providers.yaml`, `secrets/web-search.yaml`, `secrets/github.yaml`, `secrets/sourcegraph.yaml` — so that a host decrypts only the groups its selected aspects consume.

#### Scenario: A shared API key is added

- **WHEN** a provider key is used by multiple features
- **THEN** it SHALL be declared as a secret in the shared credentials aspect, in the file matching its consumer group
- **AND** the declaration SHALL name only the file and the YAML key: `format`, `path`, `owner`, and `mode` stay implicit

#### Scenario: A host decrypts only what it consumes

- **WHEN** a host selects aspects that consume one consumer group and not another
- **THEN** the secret files of the unconsumed group are not decrypted on that host

### Requirement: Credentials reach consumers by the narrowest mechanism available

A credential SHALL reach its consumer by the narrowest mechanism the consumer supports. A consumer with a native key mechanism SHALL read the decrypted secret path directly, and the value SHALL NOT be exported to the environment.

#### Scenario: A consumer resolves its own key

- **WHEN** a tool can resolve a key from a path or command (pi providers and pi-web-access via `!cat <path>`, MCP headers via `!command`, magic-context via `{file:...}`)
- **THEN** the repository configuration SHALL reference the decrypted secret path
- **AND** the secret value SHALL NOT appear in the environment or in the Nix store

#### Scenario: A key is exported to the environment

- **WHEN** a key's consumer can read nothing but the environment
- **THEN** it SHALL be listed in the shared `agent-env.env` template, one line per key
- **AND** every exported key SHALL have a named env-only consumer

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

### Requirement: Cross-module references use merged placeholders

Because sops-nix builds `config.sops.placeholder.X` from the fully-merged module config, a template in one module SHALL reference a secret declared in another module via `config.sops.placeholder.X` with no special wiring.

#### Scenario: A template references a shared credential

- **WHEN** a feature-owned template (e.g. `aichat.env`, `hermes.env`, `nix-access-tokens`) needs a value declared in the shared credentials aspect
- **THEN** the template content interpolates `config.sops.placeholder.<NAME>`
- **AND** no explicit cross-module secret-forwarding is required

#### Scenario: A store-rendered config references a credential

- **WHEN** a store-rendered config file needs a credential
- **THEN** it SHALL reference `config.sops.secrets.<NAME>.path` inside a command form, never the value itself

### Requirement: The secrets monolith is removed

The repository SHALL NOT contain a single monolithic `modules/secrets.nix` that aggregates every application secret and template.

#### Scenario: A maintainer searches for the former monolith

- **WHEN** the repository is searched for `sops.secrets` or `sops.templates` declarations
- **THEN** declarations are found only in the foundation (none), the shared credentials aspect, and service feature modules — not in a central secrets registry
