# Adopt native KDE/Qt integrations

## Why

KDE Connect and the Qt platform theme are currently half-managed by hand.

- `modules/apps/kde.nix` installs `kdeconnect-kde` as a bare package but never manages the `kdeconnectd` daemon, and the NixOS target does not open KDE Connect's required ports 1714–1764 (TCP/UDP).
- `modules/desktop/portals.nix` hard-sets `QT_QPA_PLATFORMTHEME=gtk3` and `QT_QPA_PLATFORMTHEME_QT6=gtk3` via `home.sessionVariables`, while `kde.nix` installs `qt6ct`/Kvantum that nothing actually selects. The theme env is owned outside the module system and duplicated in two variables.

Both have native NixOS and Home Manager modules that own exactly this, so the lower-level wiring is unnecessary.

## What Changes

- **KDE Connect service** — Home Manager's `services.kdeconnect` owns both the package and the user `kdeconnectd` service (started on `graphical-session.target`, which UWSM provides). NixOS's `programs.kdeconnect` is enabled in parallel as the firewall owner, with `package = null` so the system doesn't double-install the package. Result: one package owner (HM) + one firewall owner (NixOS), no duplication.
- **Qt platform theme** — Home Manager's native `qt.enable` + `qt.platformTheme.name = "gtk3"` replaces the manual `home.sessionVariables` entries. The HM module owns the theme env, plugin, and systemd-user propagation. The now-dead `qt6ct`/Kvantum packages are removed from `kde.nix` (nothing selects them).
- **Kept as-is** — `QT_QPA_PLATFORM=wayland` stays a manual session variable: HM's `qt` module has no platform-backend option, and Wayland remains niri/UWSM session policy. Custom NixOS/Arch UWSM greeter/session wrapper is untouched (separate cross-platform migration).
- No new inputs or dependencies.

## Capabilities

### New Capabilities

- **`kdeconnect-service`** — KDE Connect package and user daemon owned by Home Manager; NixOS owns only the firewall ports. No duplicate package owner. Phone pairing and sync work end to end via native modules.
- **`qt-platform-theme`** — GTK3 Qt platform theme and systemd-user propagation owned by HM's native Qt module; Wayland backend remains explicit session policy; dead `qt6ct`/Kvantum packages absent.

### Modified Capabilities

None.

## Impact

- Files: `modules/apps/kde.nix`, `modules/desktop/portals.nix`, `modules/hosts/arch.nix` (NixOS aspect selection), and the invalid `intel_agc` entry in `modules/hosts/arch/_hardware.nix` found by the build gate.
- Both Home Manager and NixOS evals must pass (flake checks include `home-manager-activation`, `nixos-system`, and the VM boot gate).
- Post-switch: re-pair the phone on KDE Connect; manually verify a Qt app picks up the GTK3 theme.
