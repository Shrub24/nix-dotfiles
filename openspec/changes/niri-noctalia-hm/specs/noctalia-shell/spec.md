## Purpose

Declaratively manages the Noctalia v5 desktop shell (bar, launcher, control center, notifications, lock screen) via the upstream `programs.noctalia` home-manager module, integrated with niri as the replacement for the DMS shell layer.

## ADDED Requirements

### Requirement: Noctalia is configured declaratively
The system SHALL render Noctalia configuration from `programs.noctalia.settings` into `~/.config/noctalia/`, using the upstream module (`inputs.noctalia.homeModules.default`), with the package pinned to nixpkgs' `pkgs.noctalia` (prebuilt 5.0.0-beta.7).

#### Scenario: Config is rendered from module options
- **WHEN** the home-manager configuration is activated
- **THEN** `~/.config/noctalia/` contains the TOML rendered from `programs.noctalia.settings` as a store-linked file

#### Scenario: Package comes from nixpkgs
- **WHEN** the configuration is built
- **THEN** `programs.noctalia.package` resolves to `pkgs.noctalia`, overriding the upstream module's own derivation default

### Requirement: Noctalia starts with the niri session
The system SHALL autostart Noctalia when the niri session starts via `spawn-at-startup "noctalia"` in the niri configuration.

#### Scenario: Shell starts with the compositor
- **WHEN** a niri session starts
- **THEN** the `noctalia` process is spawned at startup and the shell surfaces (bar, launcher) are available

### Requirement: Shell windows behave with niri
The system SHALL apply niri window rules for Noctalia: floating settings window for `app-id "dev.noctalia.Noctalia"` with fixed default size, rounded corners, and `debug.honor-xdg-activation-with-invalid-serial` enabled.

#### Scenario: Settings window floats
- **WHEN** the Noctalia settings window opens
- **THEN** it is floating with a fixed 1080x920 default size and rounded corners

### Requirement: Noctalia provides the greetd greeter
System-manager SHALL configure greetd to run upstream Noctalia Greeter 1.2.1, provide its runtime dependencies, create its persistent state through tmpfiles, and authorize only the active local user to apply appearance state without a polkit prompt. Home Manager SHALL provide the matching appearance-sync helper, while synchronized state remains separate from declarative greeter settings.

#### Scenario: Login greeter starts
- **WHEN** greetd starts
- **THEN** Noctalia Greeter renders and lists the system-managed Wayland sessions

#### Scenario: Appearance sync
- **WHEN** Noctalia synchronizes greeter appearance
- **THEN** theme, wallpaper, and supported output state are written to mutable greeter sync state without modifying declarative `greeter.toml`

#### Scenario: Session handoff
- **WHEN** greetd starts the Niri UWSM session
- **THEN** UWSM output is preserved in the journal and not displayed on the greeter VT

### Requirement: Shell controls are bound to keys
The system SHALL bind Noctalia IPC commands to the keys formerly used by DMS: volume, brightness, mute, settings/control-center toggle, launcher, and lock screen via `noctalia msg`.

#### Scenario: Media keys control the shell
- **WHEN** `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` / `XF86AudioMute` / `XF86MonBrightnessUp` / `XF86MonBrightnessDown` are pressed
- **THEN** the equivalent `noctalia msg volume-*` / `brightness-*` commands execute

#### Scenario: Lock screen is available
- **WHEN** the lock keybind is pressed
- **THEN** `noctalia msg session lock` executes and the session is locked

### Requirement: Runtime state is separated from declarative config
The system SHALL treat `~/.local/state/noctalia/settings.toml` (GUI-managed overrides) as runtime state outside declarative control, since it takes precedence over rendered config.

#### Scenario: GUI overrides are documented
- **WHEN** declarative settings are changed in the flake
- **THEN** the state-dir override file is the known precedence boundary, and stale GUI overrides are cleared explicitly rather than by declarative means
