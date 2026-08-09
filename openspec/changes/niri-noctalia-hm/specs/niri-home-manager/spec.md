## Purpose

Declaratively manages the niri Wayland compositor configuration from the home-manager flake using the native `wayland.windowManager.niri` module, replacing the imperative `~/.config/niri/config.kdl` on the Arch host.

## ADDED Requirements

### Requirement: Niri is configured declaratively
The system SHALL render the niri configuration from `wayland.windowManager.niri.settings` (structured KDL attrsets) and `extraConfig` (verbatim KDL lines) into `~/.config/niri/config.kdl` as a home-manager-managed store symlink.

#### Scenario: Config is generated from module options
- **WHEN** the home-manager configuration is activated
- **THEN** `~/.config/niri/config.kdl` is a symlink into the nix store containing the rendered KDL from `settings` and `extraConfig`

#### Scenario: Existing imperative config is not silently lost
- **WHEN** activation replaces the pre-existing imperative `config.kdl`
- **THEN** the original file content is preserved in the repository as a committed pre-migration backup

### Requirement: Generated config is validated before deployment
The system SHALL run `niri validate` against the generated config at build time whenever `checkConfig` is enabled and a package is set, and fail the build on invalid KDL.

#### Scenario: Invalid configuration fails the build
- **WHEN** the rendered KDL fails `niri validate`
- **THEN** the build fails before any activation happens

### Requirement: Niri runtime wiring is managed
The system SHALL install the niri package and its systemd units, and SHALL set up the xdg-desktop-portal integration (gnome portal package) when enabled.

#### Scenario: Session integration is installed
- **WHEN** niri is enabled
- **THEN** the niri binary is on PATH, its systemd user units are available, and portal configuration prefers the gnome portal

### Requirement: Keybinding behavior is preserved across the migration
The system SHALL keep the existing niri keybinding set functional after the migration, with DMS IPC binds re-pointed to the replacement shell's IPC (`noctalia msg`).

#### Scenario: DMS binds are replaced
- **WHEN** the migrated config is loaded
- **THEN** each former `dms ipc call ...` bind executes the equivalent Noctalia IPC command, and no bind references the removed `dms` binary

### Requirement: Login sessions use the managed niri package
System-manager SHALL install Niri and Niri (UWSM) session entries whose commands use absolute nix-store paths.

#### Scenario: Greetd launches Niri (UWSM)
- **WHEN** the user selects `Niri (UWSM)` in the greeter
- **THEN** UWSM resolves the managed niri binary without depending on the systemd user manager's `PATH`

## ADDED Requirements

### Requirement: Home-manager module import
The `niri.nix` module SHALL be imported from `modules/default.nix` so the host config activates it without per-host duplication.

#### Scenario: Module is wired into the flake
- **WHEN** the flake is evaluated
- **THEN** `modules/default.nix` imports `./home/niri.nix`
