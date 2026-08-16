# keypeek-integration Specification

## Purpose
Provides a usable Keypeek launcher and correctly selects the ZMK transport for keyboards using the standard ZMK USB identity.

## Requirements

### Requirement: Keypeek has a desktop launcher

The Home Manager profile SHALL install a desktop entry that launches Keypeek from the desktop environment.

#### Scenario: User launches Keypeek from the application menu

- **WHEN** the Home Manager generation is active
- **THEN** the application menu exposes a Keypeek entry that launches the installed executable

### Requirement: Standard ZMK devices use ZMK discovery

Keypeek SHALL classify a Raw-HID device with VID:PID `1D50:615E` as ZMK before applying its QMK fallback.

#### Scenario: Sofle exposes the standard ZMK identity

- **WHEN** Keypeek discovers a `1D50:615E` Raw-HID device whose name does not contain `zmk`
- **THEN** it attempts ZMK Studio serial or BLE discovery rather than QMK/VIA RPC
