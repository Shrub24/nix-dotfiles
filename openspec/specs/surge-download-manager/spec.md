# surge-download-manager Specification

## Purpose

Provide the Surge download-manager TUI and CLI as a reproducible user tool, with an optional NixOS-only daemon. The package version is always derived truthfully from the locked `inputs.surge` revision rather than pinned to a release.

## Requirements

### Requirement: Surge is installed from the locked input with truthful version

The user environment SHALL provide Surge built from `inputs.surge.packages.${system}.default`, with `surge --version` SHALL report a version derived from the locked input metadata (`0-unstable-<date>-<rev>`), not a hardcoded release.

#### Scenario: Version verification

- **WHEN** the user runs `surge --version`
- **THEN** the command reports the input-derived version `0-unstable-<date>-<rev>` for the locked Surge revision

### Requirement: Home Manager installs the package only

The Home Manager aspect (`flake.modules.homeManager.surge`) SHALL add `pkgs.surge` to `home.packages` and SHALL NOT start the Surge server, run a user daemon, or install a system-manager service.

#### Scenario: Home Manager activation

- **WHEN** Home Manager activates the `surge` aspect
- **THEN** `surge` is on the user PATH, no user Surge daemon/unit is started, and no system-manager Surge service exists

### Requirement: NixOS aspect enables the server

The NixOS aspect (`flake.modules.nixos.surge`) SHALL add `pkgs.surge` to `environment.systemPackages` and SHALL enable the Surge server unit equivalent to the upstream service: `wantedBy = multi-user.target`, after/wants `network-online.target`, `ExecStart = ${pkgs.surge}/bin/surge server start --is-system-service`, `Restart = on-failure`, `RestartSec = 5s`.

This daemon exists ONLY on hosts that select the `nixos.surge` aspect; the Home Manager aspect installs the package without any daemon.

#### Scenario: NixOS host with the surge aspect

- **WHEN** a NixOS configuration imports the `surge` aspect
- **THEN** `surge` is on the system PATH and the `surge.service` systemd unit is enabled on `multi-user.target`
