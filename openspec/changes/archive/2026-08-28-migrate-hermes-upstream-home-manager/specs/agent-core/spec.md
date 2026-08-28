## MODIFIED Requirements

### Requirement: Flake input addition

The system SHALL add `hermes-agent` as a flake input from `github:NousResearch/hermes-agent`.

#### Scenario: Flake input present

- **WHEN** evaluating `flake.nix`
- **THEN** `inputs.hermes-agent.homeManagerModules.default` SHALL be available and importable

### Requirement: Home Manager module import

The system SHALL import `hermes-agent.homeManagerModules.default` into the Home Manager module list.

#### Scenario: Module imported

- **WHEN** the Home Manager configuration is evaluated
- **THEN** the `services.hermes-agent` option set SHALL be available

### Requirement: Service enable/disable

The Hermes Agent service SHALL be disabled by default and enabled via `services.hermes-agent.enable`.

#### Scenario: Service disabled

- **WHEN** `services.hermes-agent.enable = false`
- **THEN** no Hermes user service or Hermes-managed state SHALL be created

#### Scenario: Service enabled

- **WHEN** `services.hermes-agent.enable = true`
- **THEN** a user-scoped `hermes-agent` systemd service SHALL be created

### Requirement: Host CLI access

The host SHALL install the Hermes CLI through `programs.hermes-agent` independently of service configuration.

#### Scenario: addToSystemPackages enabled

- **WHEN** `programs.hermes-agent.enable = true`
- **THEN** the `hermes` binary SHALL be available in the user's profile

### Requirement: Documents installation

The module SHALL support installing workspace documents (SOUL.md, USER.md, etc.) into an explicit Hermes working directory.

#### Scenario: Inline document

- **WHEN** `services.hermes-agent.workingDirectory` is set and `services.hermes-agent.documents."SOUL.md" = "You are a helpful assistant."`
- **THEN** the file SHALL be installed into the configured working directory

#### Scenario: File path document

- **WHEN** `services.hermes-agent.workingDirectory` is set and `services.hermes-agent.documents."USER.md" = ./documents/USER.md`
- **THEN** the file content SHALL be installed into the configured working directory
