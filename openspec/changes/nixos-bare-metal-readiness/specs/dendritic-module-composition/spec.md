# dendritic-module-composition

## Purpose

Extends the composition model so the NixOS host embeds the full Home Manager aspect set in NixOS target mode — filtered of system-owned duplicates, driven by the native `targets.genericLinux` discriminator, and backed by a single host-owned unfree predicate.

## MODIFIED Requirements

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

## ADDED Requirements

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

The host composition SHALL define one unfree predicate lexically in `modules/hosts/arch.nix` and apply it to both the standalone Home Manager pkgs and the NixOS global pkgs; feature-owned Home Manager `nixpkgs.config` SHALL be removed so `useGlobalPkgs` is valid.

#### Scenario: One predicate covers both scopes

- **WHEN** either the standalone or the NixOS-embedded Home Manager configuration evaluates
- **THEN** both use the same host-owned unfree predicate
- **AND** no feature module declares its own `nixpkgs.config.allowUnfreePredicate`
