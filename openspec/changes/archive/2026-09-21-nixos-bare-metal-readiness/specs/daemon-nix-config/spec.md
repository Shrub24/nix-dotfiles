# daemon-nix-config

## Purpose

Moves the NixOS daemon post-build upload to the native system Niks3 auto-upload service with a root-owned token, replacing the user-runtime-socket post-build hook, and anchors daemon-level Nix policy in the NixOS system scope.

## MODIFIED Requirements

### Requirement: Daemon-visible Nix policy is managed at system scope

Settings consumed by the Nix daemon, including daemon-level substituter policy and trusted keys, SHALL be declared in the system-scoped configuration layer rather than only in user-scoped Home Manager configuration.

#### Scenario: Nix daemon evaluates substituter configuration

- **WHEN** the Nix daemon performs an operation that requires substituter or trusted key policy
- **THEN** it uses configuration declared at system scope

#### Scenario: NixOS daemon policy lives in nix.settings

- **WHEN** the NixOS target is active
- **THEN** daemon-level Nix policy is declared in the NixOS `nix.settings`
- **AND** the NixOS `nix` aspect SHALL NOT set a user-runtime-socket post-build hook

## ADDED Requirements

### Requirement: Native system Niks3 auto-upload is the NixOS post-build path

On the NixOS target, store-path upload SHALL use the native `services.niks3-auto-upload` system service with a root-owned auth token; the user-runtime uploader and its socket hook SHALL NOT be used.

#### Scenario: Native Niks3 uploads built paths

- **WHEN** the NixOS daemon finishes a build
- **THEN** the native `services.niks3-auto-upload` service uploads the store paths to the configured niks3 server
- **AND** the upload uses a root-owned token readable by the service

#### Scenario: No user-runtime post-build hook on NixOS

- **WHEN** the NixOS `nix` aspect is evaluated
- **THEN** it sets no post-build hook referencing the user runtime socket
