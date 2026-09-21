# dendritic-module-composition

## Purpose

Extends the composition model so reusable feature aspects are host-agnostic:
host facts reach each evaluation as a typed current-host projection instead of
being read from a flake-wide topology key, and native module options take
precedence over custom record fields.

## MODIFIED Requirements

### Requirement: Shared host and service data is typed and host-owned

Machine identity, architecture, home paths, and service topology SHALL be modeled
as typed top-level options (`topology.hosts`, `topology.services`) or native
options (`networking.hostName`, `home.username`, `home.homeDirectory`,
`system.stateVersion`, `pkgs.stdenv.hostPlatform.system`), each declared once — a
machine this repository configures in its own host composition, fleet-wide values
beside the schema — and read by consumers via the normal module system, never
passed through `specialArgs` or duplicated in reusable feature modules. Reusable
feature aspects SHALL read the per-evaluation current-host projection for the
machine they are composed into, and SHALL NOT read a hardcoded topology key.
Fleet-aware features MAY read the fleet registry, because that value is identical
in every evaluation.

#### Scenario: Reusable aspect needs a host path or identity

- **WHEN** a feature aspect requires a host-specific fact
- **THEN** that fact SHALL be declared once in the typed registry — by the owning
  host composition when this repository configures the machine, beside the schema
  when it only reaches it — and SHALL be projected into the evaluation as the
  current-host record, or read through the native option that already expresses it
- **AND** the aspect SHALL read it via the module system rather than an
  argument-passing bus
- **AND** the aspect SHALL NOT duplicate the literal across feature modules

#### Scenario: Aspect reads a flake-wide topology key

- **WHEN** a reusable feature aspect is evaluated
- **THEN** it SHALL NOT read `config.topology.hosts.<name>` for a specific
  machine
- **AND** per-host facts SHALL arrive through the current-host projection

#### Scenario: Native option already expresses the fact

- **WHEN** a fact has a native home in the relevant class
- **THEN** consumers SHALL read the native option
- **AND** the shared aspect SHALL NOT restate it as a literal or a custom record
  field

#### Scenario: Host-specific literal inside a reusable aspect

- **WHEN** a reusable aspect would otherwise carry a machine's own data (disk
  identifiers, device paths, kernel command lines)
- **THEN** that data SHALL live in the owning host's raw module
- **AND** the aspect SHALL retain only behaviour common to every host that
  selects it
