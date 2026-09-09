# surge-download-manager Specification

## Purpose

Provide the Surge download-manager TUI and CLI as a reproducible user tool, with an optional NixOS-only daemon. The package is `pkgs.surge-downloader` from nixpkgs — no wrapper, no extra flake input.

## Requirements

### Requirement: Surge is installed from nixpkgs with truthful version

The user environment SHALL provide Surge via `pkgs.surge-downloader`, with `surge --version` SHALL report the nixpkgs version (0.12.1 at adoption), not a hardcoded release.

#### Scenario: Version verification

- **WHEN** the user runs `surge --version`
- **THEN** the command reports the nixpkgs version for the locked nixpkgs revision

### Requirement: Home Manager installs the package only

The Home Manager aspect (`flake.modules.homeManager.surge`) SHALL add `pkgs.surge-downloader` to `home.packages` and SHALL NOT start the Surge server, run a user daemon, or install a system-manager service.

#### Scenario: Home Manager activation

- **WHEN** Home Manager activates the `surge` aspect
- **THEN** `surge` is on the user PATH, no user Surge daemon/unit is started, and no system-manager Surge service exists

### Requirement: NixOS aspect enables the server

The NixOS aspect (`flake.modules.nixos.surge`) SHALL add `pkgs.surge-downloader` to `environment.systemPackages` and SHALL enable the Surge server unit equivalent to the upstream service: `wantedBy = multi-user.target`, after/wants `network-online.target`, `ExecStart = ${pkgs.surge-downloader}/bin/surge server start`, `Restart = on-failure`, `RestartSec = 5s`.

This daemon exists ONLY on hosts that select the `nixos.surge` aspect; the Home Manager aspect installs the package without any daemon.

#### Scenario: NixOS host with the surge aspect

- **WHEN** a NixOS configuration imports the `surge` aspect
- **THEN** `surge` is on the system PATH and the `surge.service` systemd unit is enabled on `multi-user.target`
