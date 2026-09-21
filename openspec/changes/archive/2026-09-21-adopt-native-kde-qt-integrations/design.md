# Design

## One dendritic feature file publishes both class values

`modules/apps/kde.nix` stays the single feature file and exports both
`flake.modules.homeManager.kde-apps` and `flake.modules.nixos.kde-apps`.
Add `kde-apps` to the normal `nixosAspects` list in `modules/hosts/arch.nix`;
the VM checks (`vm-desktop`, `vm-skeleton-boot`) inherit it harmlessly.

## KDE Connect: split user-daemon vs firewall ownership

- HM: `services.kdeconnect.enable = true` — package + user `kdeconnectd` on
  `graphical-session.target` (UWSM provides it). Drop the bare
  `kdeconnect-kde` package entry (HM module owns it now).
- NixOS: `programs.kdeconnect.enable = true; package = null;` — opens
  TCP/UDP 1714–1764, adds no duplicate system package.
- `services.kdeconnect.indicator` left off (not requested).

## Qt: native GTK3 platform theme, keep Wayland explicit

HM `qt.enable = true` + `qt.platformTheme.name = "gtk3"` replaces the manual
`QT_QPA_PLATFORMTHEME`/`QT_QPA_PLATFORMTHEME_QT6` entries. Remove `qt6ct` and
`qtstyleplugin-kvantum` from `kde.nix` (unselected). Keep only
`QT_QPA_PLATFORM=wayland` in `portals.nix` (HM Qt has no platform-backend
option; Wayland is session policy).

## Out of scope

Custom NixOS/Arch UWSM greeter/session wrapper (separate cross-platform
migration) and KDE Connect indicator.

## Manual post-switch verification

1. `systemctl --user status kdeconnect` — active.
1. Confirm firewall ranges 1714–1764 TCP/UDP (`nixos-firewall-tool` or `nft list ruleset`).
1. Re-pair the phone / confirm sync.
1. Launch one Qt app (e.g. `dolphin`) and confirm GTK3 theme.

## Rollback

Restore the prior `kdeconnect-kde` package entry and the manual
`QT_QPA_PLATFORMTHEME`/`QT_QPA_PLATFORMTHEME_QT6` session variables; remove
`services.kdeconnect`, `programs.kdeconnect`, and `qt.enable`.
