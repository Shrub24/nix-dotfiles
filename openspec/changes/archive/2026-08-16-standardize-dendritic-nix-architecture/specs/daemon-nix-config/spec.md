## MODIFIED Requirements

### Requirement: nixbuild.net access is available to daemon-scoped execution

The system SHALL provide nixbuild.net access configuration and credentials in root-owned system scope so daemon-scoped Nix execution does not depend on Home Manager state or an interactive user shell.

#### Scenario: Daemon-scoped build uses nixbuild.net

- **WHEN** a daemon-scoped Nix operation needs to access `ssh-ng://eu.nixbuild.net`
- **THEN** the required access configuration and credential SHALL be available from system-managed state
- **AND** the credential SHALL NOT be stored in the Nix store or a user-managed path

#### Scenario: Nixbuild credential rotates

- **WHEN** system-scoped secret activation replaces the Nixbuild credential
- **THEN** `nix-daemon.service` SHALL be ordered after secret installation
- **AND** the daemon SHALL be restarted through declarative service integration

## ADDED Requirements

### Requirement: System secrets use a root-owned decryption identity

System-manager secrets SHALL be decrypted using a pre-generated root-owned age identity that is independent of the Home Manager user's identity.

#### Scenario: System secrets activate

- **WHEN** system-manager installs root-owned secrets
- **THEN** it SHALL use a persistent age identity readable only by root
- **AND** the encrypted secret recipients SHALL include that identity
