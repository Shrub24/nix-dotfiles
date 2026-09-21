# niri-home-manager

## Purpose

Registers the niri session through native UWSM compositor registration on the NixOS target, leaving the Home Manager niri configuration unchanged on non-NixOS hosts.

## ADDED Requirements

### Requirement: niri session is registered through native UWSM

On the NixOS target, the niri session SHALL be registered as a compositor via the native UWSM compositor registration; the Home Manager niri configuration SHALL remain unchanged on non-NixOS hosts.

#### Scenario: NixOS registers niri with UWSM

- **WHEN** the NixOS target is active
- **THEN** UWSM is registered with niri as its compositor
- **AND** the niri session is launched through UWSM at login

#### Scenario: Arch host is unchanged

- **WHEN** the standalone Arch Home Manager configuration is evaluated
- **THEN** the niri configuration stays as today with no NixOS UWSM registration
