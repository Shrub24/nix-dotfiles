# dendritic-module-composition Specification

## Purpose

Defines how feature-owned Nix aspects are discovered, published, and explicitly composed into host outputs without crossing Home Manager and system privilege boundaries.

## Requirements

### Requirement: Features publish composable aspects

Each active feature SHALL publish its user-scoped and system-scoped configuration as separate composable aspects when it owns behavior in those scopes.

#### Scenario: Feature spans privilege boundaries

- **WHEN** a feature owns both user configuration and root-owned system behavior
- **THEN** each scope SHALL be independently selectable by host composition
- **AND** system-owned behavior SHALL NOT be implemented through the user-scoped aspect

### Requirement: Hosts explicitly select active aspects

Each host SHALL explicitly compose the feature aspects it uses rather than receiving every discovered module implicitly.

#### Scenario: Dormant feature file exists

- **WHEN** a feature module is present but its aspect is not selected by a host
- **THEN** that feature SHALL contribute no package, option, file, service, or activation behavior to the host

#### Scenario: NixOS host embeds the Home Manager aspect set

- **WHEN** the NixOS host composition is evaluated
- **THEN** it embeds the full selected Home Manager aspect set in NixOS target mode, minus the aspects whose services or packages the NixOS target owns
- **AND** the NixOS target owns those system services and packages instead
- **AND** every embedded aspect remains explicitly selected through the normal aspect lists

### Requirement: Automatic discovery is structurally safe

Automatic module discovery SHALL be limited to files that conform to the repository's flake-module contract.

#### Scenario: Discovery scans the module root

- **WHEN** the flake evaluates the automatic discovery tree
- **THEN** every discovered file SHALL be valid in that tree's module context
- **AND** raw Home Manager modules, raw system-manager modules, package functions, generated files, and disabled support files SHALL remain outside the scan scope

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
in every evaluation. A host's primary user SHALL be one structured value in that
registry carrying the account name and numeric UID; NixOS SHALL create that
account and Home Manager SHALL own its user configuration.

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

#### Scenario: Host composes the primary user

- **WHEN** a host declares its primary user's name and UID in the typed registry
- **THEN** NixOS and Home Manager user keys SHALL derive from that declaration
- **AND** raw host modules SHALL receive the value through explicit lexical closure rather than `specialArgs`

### Requirement: NixOS hosts embed Home Manager natively

The NixOS host SHALL embed Home Manager through `home-manager.nixosModules.home-manager` with `useGlobalPkgs = true` and `useUserPackages = true`, and SHALL NOT pass host facts through `specialArgs` or `extraSpecialArgs`.

#### Scenario: Embedded Home Manager uses global packages

- **WHEN** the NixOS host is evaluated
- **THEN** Home Manager is embedded via the NixOS home-manager module with global pkgs and user packages enabled
- **AND** no `specialArgs` or `extraSpecialArgs` argument bus is introduced

### Requirement: Target mode is discriminated by targets.genericLinux

The host composition SHALL set the native `targets.genericLinux.enable` option explicitly beside the shared raw home module in each evaluation; affected Home Manager modules SHALL branch on that normal `config` value rather than on an argument bus.

#### Scenario: Arch evaluation enables generic Linux

- **WHEN** the standalone Arch Home Manager configuration is evaluated
- **THEN** `targets.genericLinux.enable` is true

#### Scenario: NixOS evaluation disables generic Linux

- **WHEN** the NixOS-embedded Home Manager configuration is evaluated
- **THEN** `targets.genericLinux.enable` is false
- **AND** affected modules read the target from `config` to select target-specific behavior

### Requirement: Unfree policy is host-owned

The host composition SHALL define one unfree predicate lexically in `modules/hosts/legion.nix` and apply it to both the standalone Home Manager pkgs and the NixOS global pkgs; feature-owned Home Manager `nixpkgs.config` SHALL be removed so `useGlobalPkgs` is valid.

#### Scenario: One predicate covers both scopes

- **WHEN** either the standalone or the NixOS-embedded Home Manager configuration evaluates
- **THEN** both use the same host-owned unfree predicate
- **AND** no feature module declares its own `nixpkgs.config.allowUnfreePredicate`
