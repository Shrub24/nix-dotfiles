## Purpose

Retire unused agent tools so the declared configuration, service catalog, and maintained documentation describe only supported components.

## ADDED Requirements

### Requirement: Inactive agent tools have no managed footprint

The system SHALL not expose Agentmemory or III Engine through its package overlay, Home Manager configuration, managed services, or web-service catalog.

#### Scenario: Configuration is evaluated

- **WHEN** the repository's flake configuration is evaluated
- **THEN** it SHALL not require an Agentmemory or III Engine derivation
- **AND** it SHALL not declare an Agentmemory service, integration, or catalog entry

### Requirement: Maintained documentation reflects the active agent stack

The system SHALL remove Agentmemory and III Engine from maintained architecture, structure, README, and service-catalog documentation.

#### Scenario: A user consults maintained documentation

- **WHEN** a user reads the repository's current documentation
- **THEN** it SHALL not present Agentmemory or III Engine as an installed or supported component
- **AND** archived historical records MAY retain their original context
