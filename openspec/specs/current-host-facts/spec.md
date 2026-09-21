# current-host-facts Specification

## Purpose

Defines how each host evaluation receives a typed record of its own identity and
peers, and how reusable feature aspects consume that record instead of reading a
flake-wide topology key.

## Requirements

### Requirement: The fleet registry stays the single source of truth

Machine entries (`topology.hosts.<name>`) and service endpoints
(`topology.services.<name>`) SHALL remain typed flake-parts options, each
declared once: a machine this repository configures declares its own entry in its
own host composition, while the machines it only reaches and the service
endpoints are declared beside the schema in `modules/policy/topology.nix`. Each
entry SHALL carry the login user used to reach that machine. Peer and alias lists
SHALL be derived from the registry rather than maintained as parallel literals.

#### Scenario: A machine is registered once

- **WHEN** a machine is added to the fleet registry
- **THEN** its system, login user, and primary user (where the repository owns
  the account) SHALL be declared in that single entry
- **AND** no feature module SHALL repeat the machine's hostname, login user, or
  architecture as a literal

#### Scenario: Peer lists are derived

- **WHEN** a feature needs the set of other machines reachable from the host
- **THEN** that set SHALL be derived from the registry for the current
  evaluation
- **AND** a hand-maintained peer list SHALL NOT exist beside the registry

### Requirement: Each host evaluation receives a typed current-host record

Every NixOS, Home Manager, and system-manager evaluation SHALL receive a typed
`currentHost` record through the normal module system, using one shared schema
across all three classes. The record SHALL be passed as a module value — never
through `specialArgs` or `extraSpecialArgs`.

#### Scenario: Host composition projects its own record

- **WHEN** a host composition builds its module lists
- **THEN** it SHALL select its own registry entry once and set `currentHost` in
  every evaluation it builds
- **AND** the record SHALL be a normal module definition

#### Scenario: A feature needs host identity

- **WHEN** a reusable feature aspect requires the current machine's identity
- **THEN** it SHALL read `config.currentHost`
- **AND** it SHALL NOT read a hardcoded topology key such as
  `topology.hosts.arch`

#### Scenario: No argument bus is introduced

- **WHEN** the host outputs are evaluated
- **THEN** no `specialArgs` or `extraSpecialArgs` value SHALL be introduced to
  carry host facts
- **AND** no reusable feature module SHALL import a host or topology file
