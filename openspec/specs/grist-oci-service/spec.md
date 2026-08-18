# grist-oci-service Specification

## Purpose

Provide a durable, private Grist workspace on the configured host without
requiring a separately managed database or exposing the service to the LAN.

## Requirements

### Requirement: Managed local Grist service

The system SHALL provide an explicitly enabled user service that starts a
pinned Grist OCI image and exposes its HTTP interface on loopback port 8484.

#### Scenario: Service is enabled

- **WHEN** the host enables the Grist feature and applies its Home Manager configuration
- **THEN** the Grist user service is enabled and reachable at `http://127.0.0.1:8484/`

### Requirement: Durable single-user workspace state

The system SHALL retain Grist documents, account metadata, and sessions in a
user-owned persistent directory across service restarts and configuration
switches.

#### Scenario: Service restarts

- **WHEN** the Grist service is restarted after a document is created
- **THEN** the document remains available after the service becomes ready

### Requirement: Local-only protected access

The system SHALL bind Grist only to loopback, require the Grist login flow,
and configure the host-selected initial administrator and single organization.

#### Scenario: Network access is attempted

- **WHEN** a client connects to the host's non-loopback address on port 8484
- **THEN** the Grist service is not reachable through that address

### Requirement: Managed session secret

The system SHALL supply Grist's session-signing secret from user-scoped
encrypted configuration without storing the secret in the Nix store or the
systemd unit definition.

#### Scenario: Secret rotation

- **WHEN** the encrypted Grist session secret changes and the Home Manager configuration is applied
- **THEN** the Grist service restarts using the newly rendered secret
