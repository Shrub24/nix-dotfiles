# nixos-bare-metal-readiness

## Purpose

Makes `nixosConfigurations.shrub` a switchable bare-metal host: the full Home Manager composition embedded in NixOS target mode, hardware and firmware enabled, the live host's identity and service topology preserved, and validation kept to the existing scoped checks. A prerequisite for `nixos-dual-boot-install`, which owns all install-day work.

## ADDED Requirements

### Requirement: The NixOS toplevel is fully buildable

A full build of the `nixosConfigurations.shrub` toplevel SHALL transitively build the embedded Home Manager configuration and every selected unfree and service package; evaluation-only checks SHALL NOT be treated as sufficient.

#### Scenario: Full toplevel build

- **WHEN** the `nixos-system` check builds the NixOS toplevel
- **THEN** the resulting closure includes the embedded Home Manager activation and all selected unfree and service packages
- **AND** no install-day provisioning step is required for the build to succeed

### Requirement: Hardware and firmware are enabled

The NixOS host SHALL enable redistributable firmware, the stable NVIDIA driver with the open kernel module, I2C, fwupd, the CUDA toolkit, and libcamera. The CUDA toolkit and libcamera SHALL be supplied by the embedded NixOS-target Home Manager configuration and SHALL NOT be included by the standalone generic-Linux Home Manager configuration.

#### Scenario: Firmware, drivers, and tooling are in the closure

- **WHEN** the NixOS toplevel is built
- **THEN** redistributable firmware and the stable NVIDIA driver with the open kernel module are enabled
- **AND** I2C and fwupd are enabled
- **AND** the embedded NixOS Home Manager configuration includes the CUDA toolkit and libcamera while the standalone generic-Linux Home Manager configuration does not

### Requirement: Live host identity is preserved

The NixOS host SHALL reproduce the live Arch host identity: the primary user's primary group has GID 1000 as a private group, the default locale is `en_AU.UTF-8`, the kernel parameter `nvme_core.default_ps_max_latency_us=0` is present, swap is provided only by zram, and no hibernation is configured.

#### Scenario: Identity survives the target switch

- **WHEN** the NixOS host configuration is evaluated
- **THEN** the primary user's primary group GID is 1000, the default locale is `en_AU.UTF-8`, and the NVMe latency parameter is in the kernel parameters
- **AND** swap is provided only by zram with no hibernation or resume device configured

### Requirement: Selected services are tailnet-scoped

The native Mosh package SHALL be present with its UDP range permitted only on `tailscale0`; LiteLLM TCP 8765 and web-catalog TCP 8123 SHALL be reachable only on `tailscale0`; none of these ports SHALL be exposed globally; Surge SHALL remain unselected.

#### Scenario: Mosh is reachable over the tailnet only

- **WHEN** the NixOS firewall is active
- **THEN** the Mosh UDP range is allowed on `tailscale0` only
- **AND** no Mosh or user web port is opened on global interfaces

#### Scenario: User web services are reachable only on the tailnet

- **WHEN** the NixOS firewall is active
- **THEN** LiteLLM TCP 8765 and web-catalog TCP 8123 are allowed on `tailscale0`
- **AND** neither port is opened on global interfaces

#### Scenario: Surge stays unselected

- **WHEN** the NixOS host configuration is evaluated
- **THEN** Surge contributes no package or service unless explicitly selected later

### Requirement: Syncthing identity is preserved

The NixOS Syncthing service SHALL use the existing Home Manager state path `~/.local/state/syncthing` as its config directory so configuration and device identity survive the target switch.

#### Scenario: Config directory points at the live state

- **WHEN** the NixOS Syncthing service is evaluated
- **THEN** its config directory is `~/.local/state/syncthing`
- **AND** existing devices and folders are retained rather than overridden

### Requirement: Snapshot and mount policy matches the live host

Snapper SHALL be configured for the root, home, and data btrfs volumes; the Shared NTFS mount SHALL use `nofail` and derive its ownership options from the topology primary user.

#### Scenario: Snapshots cover the btrfs volumes

- **WHEN** the NixOS host boots
- **THEN** Snapper manages the root, home, and data volumes

#### Scenario: Shared NTFS is non-fatal

- **WHEN** the Windows data partition is unavailable at boot
- **THEN** `/mnt/Shared` is skipped rather than blocking the boot
- **AND** its configured ownership uses the topology primary user's UID and GID

### Requirement: Validation uses the existing scoped checks

Repository validation SHALL keep the existing VM checks, and `vm-desktop` SHALL verify embedded Home Manager activation succeeds. It SHALL NOT add a new headless graphical-output assertion.

#### Scenario: Embedded Home Manager activates in the desktop VM

- **WHEN** `vm-desktop` completes its login flow
- **THEN** `home-manager-saurabhj.service` has succeeded without a Ghostty configuration failure
- **AND** no new headless graphical-output assertion is introduced
