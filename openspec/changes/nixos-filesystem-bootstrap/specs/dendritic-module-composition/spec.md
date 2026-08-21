## MODIFIED Requirements

### Requirement: Shared host and service data is typed and host-owned

Machine identity, architecture, home paths, and service topology SHALL be
modeled as typed top-level options (`topology.hosts`, `topology.services`) or
native Home Manager options (`home.username`, `home.homeDirectory`,
`pkgs.stdenv.hostPlatform.system`), declared once at the host composition layer
and read by consumers via the normal module system — never passed through
`specialArgs` or duplicated in reusable feature modules. A host's primary user
SHALL be one structured topology value containing the account name and numeric
UID; NixOS SHALL create that account and Home Manager SHALL own its user
configuration.

#### Scenario: Reusable aspect needs a host path or identity

- **WHEN** a feature aspect requires a host-specific fact
- **THEN** the host composition SHALL declare that fact once in the typed topology option or as a native option value
- **AND** the aspect SHALL read it via the module system rather than an argument-passing bus
- **AND** the aspect SHALL NOT duplicate the literal across feature modules

#### Scenario: Host composes the primary user

- **WHEN** a host declares its primary user's name and UID in typed topology
- **THEN** NixOS and Home Manager user keys SHALL derive from that declaration
- **AND** raw host modules SHALL receive the value through explicit lexical closure rather than `specialArgs`
