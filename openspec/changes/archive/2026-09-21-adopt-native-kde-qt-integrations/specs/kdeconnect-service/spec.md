# kdeconnect-service

## Purpose

This capability makes KDE Connect function end to end on the desktop: the package and the user daemon are owned by the Home Manager configuration, while the NixOS target owns only the firewall ports it needs without installing a duplicate system package.

## ADDED Requirements

### Requirement: Home Manager owns the package and user daemon

The `kde-apps` Home Manager module SHALL enable `services.kdeconnect`, which installs `kdeconnect-kde` as the user's package and runs the `kdeconnectd` user daemon under the graphical user session.

#### Scenario: Daemon runs under the graphical session

- **WHEN** the user session reaches `graphical-session.target` (provided by UWSM)
- **THEN** `kdeconnectd` runs as a user service and `systemctl --user status kdeconnect` reports the unit active

#### Scenario: No duplicate package owner

- **WHEN** the Home Manager configuration evaluates
- **THEN** `kdeconnect-kde` appears exactly once in the user's `home.packages`, owned by the `services.kdeconnect` module and not as a bare package entry

### Requirement: NixOS opens firewall ports without a second package

The `kde-apps` NixOS module SHALL enable `programs.kdeconnect` with `package = null`, opening TCP and UDP ports 1714–1764 while adding no duplicate system-level package.

#### Scenario: Firewall ranges are open

- **WHEN** the NixOS target is active
- **THEN** the NixOS firewall opens TCP and UDP ports 1714–1764

#### Scenario: No duplicate system package

- **WHEN** `package = null` is set
- **THEN** `kdeconnect-kde` does not appear in the system-level package closure

### Requirement: Firewall ownership is NixOS-only

The `kde-apps` NixOS module SHALL be wired only into the NixOS configuration (`nixosAspects` on the Arch host), so firewall-port ownership exists solely on the NixOS target.

#### Scenario: NixOS target opens ports

- **WHEN** the NixOS target is active
- **THEN** firewall rules for 1714–1764 are present

#### Scenario: Non-NixOS host produces no firewall change

- **WHEN** a non-NixOS host (Arch/system-manager) evaluates the Home Manager configuration
- **THEN** no NixOS firewall change is produced, while the HM user daemon may still run under its graphical session

### Requirement: No indicator service

The `kde-apps` module SHALL NOT enable `services.kdeconnect.indicator`.

#### Scenario: Indicator remains off

- **WHEN** the user session is set up
- **THEN** no `kdeconnect-indicator` user service is present in the generated systemd units
