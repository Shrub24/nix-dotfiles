# qt-platform-theme

## Purpose

This capability gives Qt applications a consistent GTK3 platform theme using the native Home Manager Qt module, which emits `QT_QPA_PLATFORMTHEME = "gtk3"` and propagates it through the systemd user environment, while keeping the Wayland backend as an explicit session policy and removing the previously unselected QT tools.

## ADDED Requirements

### Requirement: Native Qt integration sets the GTK3 platform theme

The `kde-apps` Home Manager module SHALL enable `qt.enable` with `qt.platformTheme.name = "gtk3"`, and qt6ct/Kvantum packages SHALL be removed from `home.packages` while unselected.

#### Scenario: Theme applies to desktop-started apps

- **WHEN** a Qt application is started from the desktop
- **THEN** it renders with the GTK3 platform theme

#### Scenario: Theme applies to systemd-started apps

- **WHEN** a Qt application is started from a systemd user service
- **THEN** the GTK3 platform theme is propagated through the Qt module's systemd-user mechanism

#### Scenario: Dead theme packages are absent

- **WHEN** the Home Manager configuration evaluates
- **THEN** `qt6ct` and `qtstyleplugin-kvantum` do not appear in the user's `home.packages`, and no Kvantum/qt5ct/qt6ct style or theme is selected

### Requirement: No manual Qt theme variables

`modules/desktop/portals.nix` SHALL NOT declare `QT_QPA_PLATFORMTHEME` or `QT_QPA_PLATFORMTHEME_QT6`; the GTK3 theme comes from `qt.platformTheme.name = "gtk3"` instead.

#### Scenario: Theme variables sourced from native module

- **WHEN** the final evaluated Home Manager config is inspected
- **THEN** `QT_QPA_PLATFORMTHEME = "gtk3"` is present from the native `qt.platformTheme.name`, and `QT_QPA_PLATFORMTHEME_QT6` is absent

#### Scenario: portals.nix declares no manual theme variable

- **WHEN** `modules/desktop/portals.nix` `home.sessionVariables` is inspected
- **THEN** it contains no `QT_QPA_PLATFORMTHEME` and no `QT_QPA_PLATFORMTHEME_QT6`

### Requirement: Wayland backend remains explicit session policy

`QT_QPA_PLATFORM=wayland` SHALL remain a manual entry in `modules/desktop/portals.nix` session variables.

#### Scenario: Wayland stays set

- **WHEN** the session variables are evaluated
- **THEN** `QT_QPA_PLATFORM = "wayland"` is present in `home.sessionVariables`
