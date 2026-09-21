# niri-home-manager Specification

## Purpose

Declaratively manages the niri Wayland compositor configuration from the home-manager flake using the native `wayland.windowManager.niri` module, replacing the imperative `~/.config/niri/config.kdl` on the Arch host.

## Requirements

### Requirement: Home-manager module import

The `niri.nix` module SHALL be imported from `modules/default.nix` so the host config activates it without per-host duplication.

#### Scenario: Module is wired into the flake

- **WHEN** the flake is evaluated
- **THEN** `modules/default.nix` imports `./home/niri.nix`

### Requirement: niri session is registered through native UWSM

On the NixOS target, the niri session SHALL be registered as a compositor via the native UWSM compositor registration; the Home Manager niri configuration SHALL remain unchanged on non-NixOS hosts.

#### Scenario: NixOS registers niri with UWSM

- **WHEN** the NixOS target is active
- **THEN** UWSM is registered with niri as its compositor
- **AND** the niri session is launched through UWSM at login

#### Scenario: Arch host is unchanged

- **WHEN** the standalone Arch Home Manager configuration is evaluated
- **THEN** the niri configuration stays as today with no NixOS UWSM registration
