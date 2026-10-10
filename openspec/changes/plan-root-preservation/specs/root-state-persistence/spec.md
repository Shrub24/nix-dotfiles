# Root State Persistence Delta

## Purpose

Define the proposed behaviour of Legion's resettable root while preserving system identity, selected durable state and independently mounted user data. These requirements are tentative until this change is approved for implementation.

## ADDED Requirements

### Requirement: Reset affects only the selected root subvolume

A reset-enabled boot SHALL discard undeclared root-subvolume contents without resetting separately retained storage. Home and data topology SHALL remain unchanged.

#### Scenario: Root reset leaves independent storage intact

- **WHEN** Legion boots with root reset enabled
- **THEN** an undeclared sentinel in the root subvolume is absent
- **AND** sentinels in persistent system state, `/nix`, home, data and retained logs remain intact

#### Scenario: Reset remains disabled during preparation

- **WHEN** persistent storage is prepared before rollout approval
- **THEN** the next boot does not reset the existing root

### Requirement: Established identity and login survive reset

Account allocation, machine identity, SSH server identity and password-based login SHALL survive root reset without relying on the discarded root's password database.

#### Scenario: Successive reset boots retain access

- **WHEN** the host completes two reset-enabled boots
- **THEN** its machine-id, user UID/GID and SSH host public keys remain unchanged
- **AND** the primary user's configured password-based login still succeeds

### Requirement: Bootstrap state is available before consumers

Persistent secret bootstrap and account state SHALL be available before their consumers run. Missing required persistence SHALL stop reset or normal consumer startup rather than silently create replacement identities.

#### Scenario: Persisted secret bootstrap restores identities

- **WHEN** a reset boot starts with the provisioned bootstrap key available
- **THEN** system secrets are installed before dependent services start
- **AND** secret and bootstrap-key permissions remain restricted

#### Scenario: Required persistence is unavailable

- **WHEN** the required persistence volume cannot be mounted
- **THEN** boot reports an actionable failure
- **AND** no fresh identity or empty state database substitutes for the missing persisted state

### Requirement: Native services retain ownership of persistent data

Persistent service data SHALL remain usable by its native owner across resets and configuration switches. Persistence SHALL NOT pin dynamic service UIDs or duplicate native initialization ownership.

#### Scenario: DynamicUser service retains its state

- **WHEN** a service with DynamicUser-backed state writes data and the host resets root
- **THEN** the service can read the previous data and write new data after restart
- **AND** its protected backing directories retain appropriate permissions

### Requirement: Supported state changes remain persistent

The persistence mechanism SHALL support the real write behaviour of selected mutable paths, including atomic replacement where the consumer uses it. Automatic-timezone behaviour SHALL remain enabled, with its reset-time retention or relearning policy documented and tested.

#### Scenario: Consumer replaces a persisted configuration file

- **WHEN** a selected consumer saves through its normal atomic-replacement operation
- **THEN** the operation succeeds and the saved state survives a root reset

#### Scenario: Automatic timezone after reset

- **WHEN** the host resets root and its location source becomes available
- **THEN** the timezone is determined by the existing automatic policy
- **AND** behaviour before that location fix matches the documented retention or relearning policy

### Requirement: Reset-disabled recovery is available

The operator SHALL have a tested reset-disabled recovery path and a documented restore procedure independent of normal reset-enabled boot. An older NixOS generation SHALL NOT be presented as recovery for data omitted from persistence.

#### Scenario: Recover without another reset

- **WHEN** the operator selects the documented recovery path
- **THEN** the selected root is not reset again
- **AND** the operator can inspect persistent state and restore backed-up data

### Requirement: Existing state is migrated before first reset

The first hardware reset SHALL require explicit approval after a verified migration, independent backup and boot-test evidence. Introducing persistence mounts SHALL NOT silently hide unmigrated state.

#### Scenario: Preparation discovers unmigrated state

- **WHEN** a candidate persistent path has live data not yet migrated and verified
- **THEN** the preparation reports the discrepancy
- **AND** root reset remains disabled

#### Scenario: Rollout evidence is incomplete

- **WHEN** backup, migration or reset/recovery boot evidence is incomplete
- **THEN** the first hardware reset is not performed
