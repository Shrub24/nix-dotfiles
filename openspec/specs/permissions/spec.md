# permissions Specification

## Purpose

TBD - created by archiving change hermes-agent. Update Purpose after archive.

## Requirements

### Requirement: Environment files for secrets

The module SHALL support referencing secret files via `environmentFiles` for API keys and tokens.

#### Scenario: Sops-managed secrets

- **WHEN** `services.hermes-agent.environmentFiles = [ config.sops.secrets."hermes/env".path ]`
- **THEN** the activation script SHALL merge the file contents into `$HERMES_HOME/.env`

#### Scenario: Multiple environment files

- **WHEN** `services.hermes-agent.environmentFiles = [ "/path/to/file1" "/path/to/file2" ]`
- **THEN** the activation script SHALL merge all files into `$HERMES_HOME/.env`

### Requirement: Non-secret environment variables

The module SHALL support setting non-secret environment variables via `environment`.

#### Scenario: Non-secret env var

- **WHEN** `services.hermes-agent.environment.HERMES_LOG_LEVEL = "debug"`
- **THEN** the activation script SHALL include `HERMES_LOG_LEVEL=debug` in `$HERMES_HOME/.env`

### Requirement: Secret isolation from Nix store

Secrets SHALL NOT be embedded in the Nix store (world-readable).

#### Scenario: No plaintext secrets in settings

- **WHEN** API keys are configured
- **THEN** they SHALL be referenced via `environmentFiles` paths, not inline in `settings` or `environment`

### Requirement: Auth file seeding

The module SHALL support seeding OAuth credentials via `authFile`.

#### Scenario: First deploy auth seed

- **WHEN** `services.hermes-agent.authFile = ./secrets/auth.json` and no `auth.json` exists
- **THEN** the activation script SHALL copy the file to `$HERMES_HOME/auth.json`

#### Scenario: Preserve existing auth

- **WHEN** `services.hermes-agent.authFile = ./secrets/auth.json` and `auth.json` already exists
- **THEN** the existing file SHALL NOT be overwritten (unless `authFileForceOverwrite = true`)
