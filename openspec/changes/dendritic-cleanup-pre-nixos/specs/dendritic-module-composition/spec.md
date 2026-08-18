## MODIFIED Requirements

### Requirement: Shared topology is a typed top-level option

Cross-feature service topology SHALL be declared once in a typed top-level flake-parts option (`topology.services.<name>.host` et al.) owned by a policy module, populated at the host composition layer, and read by consumers through the normal module system.

#### Scenario: Feature needs a remote host for a service

- **WHEN** a feature aspect requires a service host or endpoint (e.g. `databaseHost`, `niks3ServerUrl`, `remoteHosts`)
- **THEN** the host composition layer SHALL populate the typed `topology` option from one canonical definition
- **AND** the consumer SHALL read it from `config.topology.*` rather than from an ambient argument record
- **AND** SHALL NOT duplicate the literal across feature modules

### Requirement: Host identity uses native module options

Host identity and derived paths SHALL come from the owning module system's native options rather than a custom injected facts record.

#### Scenario: Reusable aspect needs username or home path

- **WHEN** a feature aspect needs `username`, `homeDirectory`, `appsDir`, or architecture
- **THEN** it SHALL use the native options (`config.home.username`, `config.home.homeDirectory`, `pkgs.stdenv.hostPlatform.system`) rather than an injected `hostFacts` record
- **AND** the host composition SHALL NOT pass `hostFacts` through `specialArgs`/`extraSpecialArgs`

### Requirement: Flake inputs are captured lexically at the feature boundary

Lower-level Home Manager / System Manager / NixOS modules SHALL NOT receive the whole `inputs` set through `specialArgs`; top-level feature publishers SHALL capture only the inputs they need, lexically, and pass them to the module via `imports`.

#### Scenario: Feature module imports an upstream flake module

- **WHEN** a feature needs an upstream `homeManagerModules`/`modules` import
- **THEN** the top-level flake-parts publisher SHALL take `inputs` lexically and place the import in the selected lower-level module's `imports`
- **AND** the lower-level module SHALL NOT destructure `inputs` from specialArgs
