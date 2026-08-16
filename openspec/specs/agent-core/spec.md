# agent-core Specification

## Purpose
TBD - created by archiving change hermes-agent. Update Purpose after archive.

## Requirements

### Requirement: Flake input addition

The system SHALL add `hermes-agent` as a flake input from `github:NousResearch/hermes-agent`.

#### Scenario: Flake input present

- **WHEN** evaluating `flake.nix`
- **THEN** `inputs.hermes-agent` SHALL be available and its `nixosModules.default` SHALL be importable

### Requirement: NixOS module import

The system SHALL import `hermes-agent.nixosModules.default` into the NixOS module list.

#### Scenario: Module imported

- **WHEN** the system configuration is evaluated
- **THEN** the `services.hermes-agent` option set SHALL be available

### Requirement: Service enable/disable

The hermes-agent service SHALL be disabled by default and enabled via `services.hermes-agent.enable`.

#### Scenario: Service disabled

- **WHEN** `services.hermes-agent.enable = false`
- **THEN** no hermes systemd service, user, or directories SHALL be created

#### Scenario: Service enabled

- **WHEN** `services.hermes-agent.enable = true`
- **THEN** a systemd service `hermes-agent` SHALL be created, running under the configured user

### Requirement: Package selection

The module SHALL allow specifying a custom hermes package.

#### Scenario: Default package

- **WHEN** no custom package is specified
- **THEN** the module SHALL use the package from the hermes-agent flake

#### Scenario: Custom package override

- **WHEN** `services.hermes-agent.package` is set to an overridden derivation
- **THEN** the module SHALL use that derivation with any extra Python packages or dependency groups

### Requirement: Model configuration

The service SHALL support declarative model configuration via `settings`.

#### Scenario: Set default model

- **WHEN** `services.hermes-agent.settings.model = "anthropic/claude-sonnet-4"`
- **THEN** the generated `config.yaml` SHALL include `model: anthropic/claude-sonnet-4`

### Requirement: Settings deep merge

The `settings` option SHALL support deep merging across multiple module definitions.

#### Scenario: Multiple settings contributions

- **WHEN** one module sets `services.hermes-agent.settings.model = "x"` and another sets `services.hermes-agent.settings.compression.enabled = true`
- **THEN** the generated `config.yaml` SHALL include both settings

### Requirement: Host CLI access

The module SHALL support adding the hermes CLI to system packages.

#### Scenario: addToSystemPackages enabled

- **WHEN** `services.hermes-agent.addToSystemPackages = true`
- **THEN** the `hermes` binary SHALL be available in system PATH and `HERMES_HOME` SHALL be exported system-wide

### Requirement: Documents installation

The module SHALL support installing workspace documents (SOUL.md, USER.md, etc.).

#### Scenario: Inline document

- **WHEN** `services.hermes-agent.documents."SOUL.md" = "You are a helpful assistant."`
- **THEN** the file SHALL be installed into the working directory

#### Scenario: File path document

- **WHEN** `services.hermes-agent.documents."USER.md" = ./documents/USER.md`
- **THEN** the file content SHALL be installed into the working directory
