## Why

Keypeek is installed but has no desktop launcher, and it misclassifies the Sofle's standard ZMK Raw-HID identity (`1D50:615E`) as QMK when the device name does not include `zmk`.

## What Changes

- Install Keypeek's upstream desktop entry and icon from the locally overridden derivation.
- Patch the locally consumed upstream Keypeek derivation so the standard ZMK VID:PID is classified as ZMK before the QMK fallback.

## Capabilities

### New Capabilities

- `keypeek-integration`: Provides a desktop launcher and reliable ZMK discovery for the configured Sofle keyboard.

### Modified Capabilities

None.

## Impact

- `flake.nix` overlay and a local patch under `pkgs/keypeek/`
- `modules/home/niri.nix`
- Rebuild and restart Keypeek after applying the Home Manager generation
