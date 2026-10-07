# surge-download-manager Specification

## Purpose

Provide the Surge download-manager TUI, CLI, and headless daemon as reproducible
user tools. The package is `pkgs.surge-downloader` from nixpkgs — no wrapper, no
extra flake input — and the daemon is a user service so the account that runs it
owns the files it writes.

## Requirements

### Requirement: Surge is installed from nixpkgs with truthful version

The user environment SHALL provide Surge via `pkgs.surge-downloader`, with `surge --version` SHALL report the nixpkgs version (0.12.1 at adoption), not a hardcoded release.

#### Scenario: Version verification

- **WHEN** the user runs `surge --version`
- **THEN** the command reports the nixpkgs version for the locked nixpkgs revision

### Requirement: Home Manager installs the package and its user daemon

The Home Manager aspect (`flake.modules.homeManager.surge`) SHALL add
`pkgs.surge-downloader` to `home.packages` and SHALL run the headless server as a
`systemd.user` service: `WantedBy = [ "default.target" ]`, after/wants
`network-online.target`, `ExecStart = ${pkgs.surge-downloader}/bin/surge server start --port 1700 --output ${config.home.homeDirectory}/Downloads`, `Restart = "on-failure"`, `RestartSec = "5s"`.

The output directory SHALL be set explicitly, because `surge server start`
defaults it to the working directory. The daemon SHALL NOT run as a system
service, and no Surge system service SHALL exist.

#### Scenario: Home Manager activation

- **WHEN** Home Manager activates the `surge` aspect
- **THEN** `surge` is on the user PATH
- **AND** the `surge` user unit is enabled on `default.target` with the port and
  output directory set explicitly
- **AND** no Surge system service exists

#### Scenario: The daemon writes where the user looks

- **WHEN** the daemon downloads a file
- **THEN** it lands under the user's own home directory
- **AND** it is owned by that user rather than by root

#### Scenario: Every host behaves identically

- **WHEN** the fleet's hosts are evaluated
- **THEN** each has the same user unit from the same aspect
- **AND** the embedded Home Manager SHALL NOT subtract the `surge` aspect
