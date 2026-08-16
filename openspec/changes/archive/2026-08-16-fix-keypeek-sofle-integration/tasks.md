## 1. Package Integration

- [x] 1.1 Extend the Keypeek overlay derivation to install upstream's desktop entry and icon.
  - refs: `flake.nix`, `cargo-appimage.desktop`, `resources/icon.svg`
  - criteria: the package exposes `share/applications/keypeek.desktop` and its declared `keypeek` icon
- [x] 1.2 Apply a local source patch that classifies ZMK's default `1D50:615E` Raw-HID identity as ZMK before QMK fallback.
  - refs: `pkgs/keypeek/zmk-default-vid-pid.patch`
  - criteria: the patch preserves Vial detection and existing name-based ZMK detection

## 2. Validation

- [x] 2.1 Build the patched Keypeek package and verify the desktop entry, icon, and patch are present in its output.
  - verify: `nix build .#homeConfigurations.saurabhj.activationPackage`
- [x] 2.2 Switch Home Manager and confirm the Sofle follows ZMK discovery without a `keyboard_info.json` prompt.
  - verify: `nh home switch path:.`, restart Keypeek with the connected Sofle
