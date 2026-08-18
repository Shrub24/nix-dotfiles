# niri-home-manager Specification

## Purpose

Declaratively manages the niri Wayland compositor configuration from the home-manager flake using the native `wayland.windowManager.niri` module, replacing the imperative `~/.config/niri/config.kdl` on the Arch host.

## Requirements

### Requirement: Home-manager module import

The `niri.nix` module SHALL be imported from `modules/default.nix` so the host config activates it without per-host duplication.

#### Scenario: Module is wired into the flake

- **WHEN** the flake is evaluated
- **THEN** `modules/default.nix` imports `./home/niri.nix`
