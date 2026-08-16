## ADDED Requirements

### Requirement: Extra packages for agent

The module SHALL support adding system packages available to the agent.

#### Scenario: Extra packages

- **WHEN** `services.hermes-agent.extraPackages = [ pkgs.ffmpeg pkgs.ripgrep ]`
- **THEN** the packages SHALL be available in the agent's PATH (per-user profile + systemd service PATH)

### Requirement: Plugin system

The module SHALL support directory-based plugins via `extraPlugins`.

#### Scenario: GitHub-fetched plugin

- **WHEN** `services.hermes-agent.extraPlugins = [ (pkgs.fetchFromGitHub { ... }) ]`
- **THEN** the plugin SHALL be symlinked into `$HERMES_HOME/plugins/` with a `nix-managed-` prefix

### Requirement: Python package plugins

The module SHALL support pip-packaged plugins via `extraPythonPackages`.

#### Scenario: Python plugin

- **WHEN** `services.hermes-agent.extraPythonPackages = [ pkgs.python312Packages.somePlugin ]`
- **THEN** the package SHALL be added to PYTHONPATH for entry-point plugin discovery

### Requirement: Dependency groups

The module SHALL support optional pyproject.toml dependency groups.

#### Scenario: Hindsight dependency group

- **WHEN** `services.hermes-agent.extraDependencyGroups = [ "hindsight" ]`
- **THEN** the hindsight optional dependencies SHALL be included in the sealed Python venv

### Requirement: Service hardening

The hermes-agent systemd service SHALL run with security hardening.

#### Scenario: Hardened service

- **WHEN** the service is running in native mode
- **THEN** it SHALL have `NoNewPrivileges = true`, `ProtectSystem = "strict"`, `PrivateTmp = true`, and `UMask = "0007"`

### Requirement: Container mode (optional)

The module SHALL support OCI container mode for agents needing self-modification.

#### Scenario: Container mode enabled

- **WHEN** `services.hermes-agent.container.enable = true`
- **THEN** the service SHALL run inside an OCI container with persistent writable layer

#### Scenario: Container host users

- **WHEN** `services.hermes-agent.container.hostUsers = [ "sidbin" ]`
- **THEN** those users SHALL get `~/.hermes` symlinks to the service state directory
