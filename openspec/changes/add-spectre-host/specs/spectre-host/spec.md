# spectre-host

## Purpose

Defines the portable NixOS host: a second machine composed from the existing
aspects, with a deliberately lean profile, a single-boot encrypted storage layout
with hibernation support, a two-phase secrets bootstrap, remote access as its
primary purpose, and validation that runs before the machine is installed.

## ADDED Requirements

### Requirement: The portable host is a composed NixOS output

The repository SHALL provide `nixosConfigurations.spectre` as a NixOS host
composed exclusively from existing named aspects plus its own raw host modules,
with no `systemConfigs` output, no standalone `homeConfigurations` output, and no
`targets.genericLinux` value.

#### Scenario: The host is composed from aspects

- **WHEN** the laptop configuration is evaluated
- **THEN** its modules SHALL be the shared NixOS and Home Manager aspects
  selected in its host composition plus the host's raw `_nixos.nix`, `_home.nix`,
  and `_hardware.nix` modules
- **AND** Home Manager SHALL be embedded through the NixOS home-manager module
  with global packages and user packages enabled

#### Scenario: One configuration path

- **WHEN** the flake outputs are listed
- **THEN** the laptop SHALL appear as a NixOS configuration only
- **AND** updating it SHALL be a single rebuild that carries both the system and
  the embedded Home Manager generation

#### Scenario: The host selects no local service tier

- **WHEN** the laptop's aspect lists are read
- **THEN** the always-on services (Grist, docs-mcp, hermes-agent, qmd,
  web-catalog, Syncthing, the niks3 uploader) SHALL NOT be selected
- **AND** clients that target those services SHALL point at the machines that run
  them

#### Scenario: Portable hardware leaves the shared aspects alone

- **WHEN** the laptop needs host-specific hardware enablement
- **THEN** that enablement SHALL live in the host's own raw modules
- **AND** no shared aspect SHALL gain a laptop-only literal or device path

#### Scenario: The application profile respects the memory budget

- **WHEN** the laptop's selected application aspects are read
- **THEN** no Chromium-class browser beyond the primary browser and no Electron
  editor SHALL be selected
- **AND** the selection SHALL keep the GUI file manager that the shared
  compositor binding spawns

#### Scenario: One shell and a lightweight agent setup

- **WHEN** the laptop's shell and agent aspects are read
- **THEN** exactly one interactive shell configuration SHALL be selected, and its
  session conveniences (reattaching a shared terminal session over ssh) SHALL be
  expressed for that shell alone
- **AND** the agent surface SHALL be limited to the interactive coding agent and
  its terminal multiplexer integration, with no second agent CLI, no agent-tool
  package set, and no agent-specific developer utility selected

### Requirement: Portable hardware is supported and probe-gated

The host SHALL enable the portable hardware path — Intel microcode, thermal and
power management, bluetooth, backlight, rotation sensing, and battery charge
threshold — and SHALL enable a fingerprint reader only when the device is
verified as supported.

#### Scenario: Unsupported fingerprint reader

- **WHEN** the machine's fingerprint reader is not on the supported device list
- **THEN** no fingerprint service SHALL be enabled
- **AND** the finding SHALL be recorded in the host's own module

#### Scenario: Thermal and power management are present

- **WHEN** the laptop boots
- **THEN** thermal management, a power profile daemon, and battery charge
  threshold control SHALL be active

### Requirement: Builder access is selected, not inherited

The laptop SHALL NOT select distributed-build configuration that requires root to
hold a builder's private key, so that a portable machine carries no system-scoped
secret in its first configuration.

#### Scenario: Portable host has no builder key

- **WHEN** the laptop configuration is evaluated
- **THEN** distributed builds against the remote builder SHALL NOT be enabled
- **AND** no root-owned ssh key for a builder SHALL be required

#### Scenario: The desktop keeps its builder

- **WHEN** the desktop configuration is evaluated
- **THEN** its builder configuration SHALL still be selected and unchanged

### Requirement: Storage is a single encrypted container with hibernation support

The storage layout SHALL consist of an ESP and one encrypted root container
covering the remainder of the disk, with btrfs subvolumes including a dedicated
swap subvolume for hibernation, and SHALL NOT reserve space for another operating
system.

#### Scenario: Hibernation works from the encrypted root

- **WHEN** the machine hibernates and is powered on again
- **THEN** the session SHALL resume without a passphrase prompt

#### Scenario: No space is held idle

- **WHEN** the disk layout is inspected after install
- **THEN** the ESP and the encrypted container SHALL claim the whole disk
- **AND** no unallocated region SHALL remain

#### Scenario: Device identity is stable

- **WHEN** the host's storage configuration is read
- **THEN** devices SHALL be referenced by filesystem UUID or partition UUID
- **AND** no kernel-assigned device number SHALL appear

### Requirement: Secrets are bootstrapped without a half-failing first switch

The first switch of the laptop SHALL NOT require any secret that does not yet
exist, and enabling secrets afterwards SHALL use a key generated on the laptop
with no other machine's private key copied to it.

#### Scenario: First switch has no key

- **WHEN** the machine switches for the first time after install
- **THEN** no secret-consuming aspect SHALL be selected
- **AND** activation SHALL complete without a decryption failure

#### Scenario: Secrets are enabled after the key exists

- **WHEN** the host's own key has been generated and registered as a recipient
- **THEN** the secret-consuming aspects SHALL be selected and the switch SHALL
  render every secret they declare

### Requirement: The portable host is reachable and validated before install day

The host SHALL be reachable over the tailnet with ssh and mosh, SHALL appear in
the fleet registry as a peer of the desktop, and SHALL be covered by the
repository's canonical validation plus a boot-level check that exercises its own
aspect composition.

#### Scenario: Remote access works from the desktop

- **WHEN** the desktop reaches the laptop by its registry name
- **THEN** ssh and mosh SHALL connect using the laptop's registered login user
- **AND** no per-machine configuration outside the registry entry SHALL be
  required

#### Scenario: A module conflict is caught before the machine exists

- **WHEN** the laptop's aspect composition is checked in CI
- **THEN** a headless VM boot test SHALL evaluate and boot that composition
- **AND** the laptop's toplevel SHALL build as part of the canonical check
