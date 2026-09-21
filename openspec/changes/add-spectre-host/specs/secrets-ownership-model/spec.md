# secrets-ownership-model

## Purpose

Extends the secrets ownership model so decryption is host-scoped: each machine
holds its own age key, recipients are declared per machine, and no machine's
private key is a copy of another's.

## MODIFIED Requirements

### Requirement: SOPS infrastructure is owned by a dedicated foundation aspect

The repository SHALL declare SOPS infrastructure — the sops-nix module import, the age key file, and the shell-activation tooling packages (`age`, `sops`) — in exactly one foundation aspect that owns no application secrets and no rendered templates.

#### Scenario: Maintainer locates SOPS infrastructure

- **WHEN** a maintainer needs to change the SOPS module import, age key path, or tooling
- **THEN** the relevant configuration is found in the foundation aspect (`modules/security/sops.nix`)
- **AND** the foundation aspect SHALL NOT declare any `sops.secrets.*` or `sops.templates.*`

#### Scenario: The foundation aspect is host-agnostic

- **WHEN** the foundation aspect is evaluated in any host
- **THEN** it SHALL reference the age key for the machine being evaluated
- **AND** it SHALL NOT name another machine's key path

## ADDED Requirements

### Requirement: Secrets are host-scoped

Every machine SHALL decrypt with its own age key, generated on that machine. A
private key SHALL NOT be copied between machines, and the recipient list of an
encrypted secret SHALL name each machine separately so a machine can be removed
from the fleet by removing its recipient and re-encrypting.

#### Scenario: A new machine joins the fleet

- **WHEN** a machine is added
- **THEN** its own age key SHALL be generated on that machine
- **AND** only its public key SHALL be registered as a recipient
- **AND** the encrypted files SHALL be re-encrypted for the new recipient set

#### Scenario: A machine is lost or retired

- **WHEN** a machine leaves the fleet
- **THEN** removing its recipient and re-encrypting SHALL be sufficient to
  exclude it
- **AND** no other machine's key SHALL need to be regenerated

#### Scenario: Bootstrap ordering

- **WHEN** a machine installs for the first time
- **THEN** the initial configuration SHALL NOT require a key
- **AND** secret-consuming aspects SHALL be added only after the machine's key
  exists and is registered
