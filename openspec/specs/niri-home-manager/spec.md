# niri-home-manager Specification

## Purpose

Declaratively manages the niri Wayland compositor configuration from the home-manager flake using the native `wayland.windowManager.niri` module, replacing the imperative `~/.config/niri/config.kdl`.

## Requirements

### Requirement: Home-manager module import

The niri configuration SHALL be published as the `niri` Home Manager aspect from `modules/desktop/niri.nix`, so automatic module discovery makes it selectable by host composition without per-host duplication.

#### Scenario: Module is wired into the flake

- **WHEN** the flake is evaluated
- **THEN** `flake.modules.homeManager.niri` is published and a host selects it through its aspect list

### Requirement: niri session is registered through native UWSM

On the NixOS target, the niri session SHALL be registered as a compositor via the native UWSM compositor registration.

#### Scenario: NixOS registers niri with UWSM

- **WHEN** the NixOS target is active
- **THEN** UWSM is registered with niri as its compositor
- **AND** the niri session is launched through UWSM at login
