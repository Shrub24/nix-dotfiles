# surge-download-manager

## Purpose

Provide the Surge download-manager TUI, CLI, and headless daemon as reproducible
user tools. The package is `pkgs.surge-downloader` from nixpkgs — no wrapper, no
extra flake input — and the daemon is a user service so the account that runs it
owns the files it writes.

## ADDED Requirements

### Requirement: Home Manager installs the package and its user daemon

The Home Manager aspect (`flake.modules.homeManager.surge`) SHALL add
`pkgs.surge-downloader` to `home.packages` and SHALL run the headless server as a
`systemd.user` service: `WantedBy = [ "default.target" ]`, after/wants
`network-online.target`, `ExecStart = ${pkgs.surge-downloader}/bin/surge server start --port 1700 --output ${config.home.homeDirectory}/Downloads`, `Restart = "on-failure"`, `RestartSec = "5s"`.

The output directory SHALL be set explicitly, because `surge server start`
defaults it to the working directory. The daemon SHALL NOT run as a system
service, and no `systemManager` Surge service SHALL exist.

#### Scenario: Home Manager activation

- **WHEN** Home Manager activates the `surge` aspect
- **THEN** `surge` is on the user PATH
- **AND** the `surge` user unit is enabled on `default.target` with the port and
  output directory set explicitly
- **AND** no system-manager or NixOS system service for Surge exists

#### Scenario: The daemon writes where the user looks

- **WHEN** the daemon downloads a file
- **THEN** it lands under the user's own home directory
- **AND** it is owned by that user rather than by root

#### Scenario: Both hosts behave identically

- **WHEN** the NixOS target and the non-NixOS host are evaluated
- **THEN** each has the same user unit from the same aspect
- **AND** the NixOS embedded Home Manager SHALL NOT subtract the `surge` aspect

## REMOVED Requirements

### Requirement: Home Manager installs the package only

Reason: replaced by "Home Manager installs the package and its user daemon". The
"no user daemon" clause is superseded — the aspect now owns the user service,
because the daemon writes files the user opens.

### Requirement: NixOS aspect enables the server

Reason: superseded by "Home Manager installs the package and its user daemon".
The NixOS-only system unit was never selected by any host — `nixosAspects` did
not contain `surge` — and its shape was wrong for a process that writes user
files. The `flake.modules.nixos.surge` aspect is deleted.
