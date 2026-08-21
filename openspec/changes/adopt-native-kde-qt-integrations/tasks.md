# Tasks

## 1. KDE Connect native ownership

- [x] 1.1 Replace bare HM package with native KDE Connect

  - refs: `modules/apps/kde.nix`, `modules/hosts/arch.nix`, `openspec/changes/adopt-native-kde-qt-integrations/specs/kdeconnect-service/spec.md`
  - criteria: In `modules/apps/kde.nix`, replace the bare `kdeconnect-kde` `home.packages` entry with `services.kdeconnect.enable = true`; publish `flake.modules.nixos.kde-apps` with `programs.kdeconnect.enable = true; package = null;`; select `kde-apps` in the host `nixosAspects` list.
  - delegate: CoderAgent
  - verify: `nix flake check --no-build --no-write-lock-file` (validation gated in 3.2); targeted eval: HM config eval shows `kdeconnect-kde` once in user packages and `services.kdeconnect` unit present; NixOS eval shows `programs.kdeconnect.package = null` with firewall rules for 1714–1764.

- [x] 1.2 Remove the nonexistent `intel_agc` initrd module exposed by the NixOS build gate.

  - refs: `modules/hosts/arch/_hardware.nix`
  - criteria: Keep the real `i915` Intel graphics driver and remove only `intel_agc`.
  - delegate: CoderAgent
  - verify: `nix build .#nixosConfigurations.arch.config.system.build.toplevel` no longer fails in `linux-*-modules-shrunk` on `intel_agc`.

- [x] 1.3 Verify KDE Connect ownership split

  - delegate: BuildAgent
  - verify: `nix build .#nixosConfigurations.arch.config.system.build.toplevel` (firewall + package closure for 1714–1764 TCP/UDP, no duplicate `kdeconnect-kde` system package); HM eval `nix build .#homeConfigurations.saurabhj.activationPackage` (single user `kdeconnect-kde` entry, `kdeconnectd` unit active on graphical-session.target).

## 2. Qt native integration

- [x] 2.1 Adopt native GTK3 platform theme

  - refs: `modules/desktop/portals.nix`, `modules/apps/kde.nix`, `openspec/changes/adopt-native-kde-qt-integrations/specs/qt-platform-theme/spec.md`
  - criteria: Set `qt.enable = true; qt.platformTheme.name = "gtk3";`; remove manual `QT_QPA_PLATFORMTHEME` and `QT_QPA_PLATFORMTHEME_QT6`; remove unselected `qt6ct`/`qtstyleplugin-kvantum`; retain `QT_QPA_PLATFORM=wayland`.
  - delegate: CoderAgent
  - verify: `nix flake check --no-build --no-write-lock-file` (validation gated in 3.2); targeted HM eval: `modules/desktop/portals.nix` `home.sessionVariables` no longer declares `QT_QPA_PLATFORMTHEME` or `QT_QPA_PLATFORMTHEME_QT6`, `qt.platformTheme.name = "gtk3"`, `qt6ct`/`qtstyleplugin-kvantum` absent from `home.packages`, `QT_QPA_PLATFORM=wayland` retained.

- [x] 2.2 Verify Qt theme integration

  - delegate: BuildAgent
  - criteria: Final evaluated HM config sets `QT_QPA_PLATFORMTHEME = "gtk3"` from native `qt.platformTheme.name` and propagates via systemd user env; `QT_QPA_PLATFORMTHEME_QT6` absent; `qt6ct`/`qtstyleplugin-kvantum` absent from `home.packages`.
  - verify: HM eval `nix build .#homeConfigurations.saurabhj.activationPackage` (result `home.sessionVariables` contains `QT_QPA_PLATFORMTHEME = "gtk3"` but no `QT_QPA_PLATFORMTHEME_QT6`; `qt6ct`/`qtstyleplugin-kvantum` absent from `home.packages`).

## 3. Quality gates

- [x] 3.1 Final code review

  - refs: whole change (`proposal.md`, `design.md`, both specs)
  - criteria: Service target/UWSM correctness, no ownership duplication, firewall correctness, no Qt env regressions (Wayland retained).
  - delegate: CodeReviewer
  - verify: No unresolved high- or medium-severity findings.

- [x] 3.2 Repository validation

  - refs: whole change
  - delegate: BuildAgent
  - verify: `just --fmt --check`; `nix flake check --no-build --no-write-lock-file`; `openspec validate --all --strict`.

- [ ] 3.3 Post-switch manual verification

  - refs: `design.md` "Manual post-switch verification"
  - criteria: `kdeconnectd` running; firewall ranges 1714–1764 TCP/UDP; phone pairing/sync; one Qt app renders GTK3.
  - verify: `systemctl --user status kdeconnect` (unit active); firewall check via `nixos-firewall-tool` or `nft list ruleset` for TCP/UDP 1714–1764; pair the phone and confirm sync from the KDE Connect app UI; launch one Qt app (e.g. `dolphin`) and confirm GTK3 theme. Manual LAN pairing is done via the app's device discovery — no single command. May remain unchecked until the user applies the switch.
