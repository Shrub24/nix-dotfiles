## Context

Keypeek's upstream flake is consumed directly as an input. Its package does not install its bundled `cargo-appimage.desktop` or icon, and its Raw-HID heuristic falls back to QMK when the standard ZMK device identity lacks `zmk` in its name.

## Goals / Non-Goals

**Goals:**

- Install the upstream desktop launcher and icon with the patched package.
- Apply a narrow, reproducible patch to the existing Keypeek derivation.

**Non-Goals:**

- Change keyboard firmware or Bluetooth identity.
- Fork or vendor Keypeek.
- Add a generic device-override interface.

## Decisions

- Use `overrideAttrs` in the existing overlay to install the upstream `cargo-appimage.desktop` and `resources/icon.svg` under the package's standard XDG data directories. This preserves upstream launcher metadata and makes the `Icon=keypeek` reference valid.
- Apply the local source patch through that same `overrideAttrs` wrapper. This preserves the upstream flake package and lock pin while making the workaround reproducible.
- Match only ZMK's documented default VID:PID (`1D50:615E`) before the existing string heuristic. A broader name-based workaround would remain unreliable for BLE devices.

## Risks / Trade-offs

- [Upstream detection logic changes] → the patch may need rebasing when the Keypeek input updates.
- [A non-ZMK device reuses the exact VID:PID] → it would be classified as ZMK; the identity is ZMK's documented default and the match is restricted to the existing Raw-HID branch.

## Migration Plan

Build and switch the Home Manager generation, restart Keypeek, and confirm the Sofle follows ZMK discovery without a `keyboard_info.json` prompt. Removing the overlay patch reverts to upstream behavior.
