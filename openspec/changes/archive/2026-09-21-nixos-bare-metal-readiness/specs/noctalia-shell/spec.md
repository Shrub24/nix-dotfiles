# noctalia-shell

## Purpose

Restores the pkexec privilege helper through the NixOS wrapper and polkit rule in NixOS mode, making the invocation path target-conditional while leaving the Arch/system-manager path unchanged.

## MODIFIED Requirements

### Requirement: Noctalia provides the greetd greeter

System-manager SHALL configure greetd to run upstream Noctalia Greeter 1.2.1, provide its runtime dependencies, create its persistent state through tmpfiles, install the validating wrapper at a fixed root-owned path via tmpfiles, and authorize pkexec of that wrapper through a polkit rule (installed via `environment.etc`) that matches the generic `org.freedesktop.policykit.exec` action by `action.lookup("program")` for the active local host user. Home Manager SHALL invoke that wrapper through `pkexec` — at `/usr/bin/pkexec` on generic-Linux targets and via the NixOS `security.wrappers` pkexec at `/run/wrappers/bin/pkexec` on the NixOS target — and SHALL NOT authorize `org.freedesktop.systemd1.manage-units`. The wrapper SHALL accept no arguments, copy only whitelisted regular non-symlink staging files from the active host user's fixed runtime directory into a root-owned temporary directory, and invoke the upstream helper only against that copy. Synchronized state remains separate from declarative greeter settings.

#### Scenario: Login greeter starts

- **WHEN** greetd starts
- **THEN** Noctalia Greeter renders and lists the system-managed Wayland sessions

#### Scenario: Appearance sync

- **WHEN** Noctalia synchronizes greeter appearance
- **THEN** theme, wallpaper, and supported output state are written without a polkit prompt to mutable greeter sync state without modifying declarative `greeter.toml`

#### Scenario: Untrusted staging input

- **WHEN** the staging directory contains a symlink, non-regular file, or unrecognized name
- **THEN** the wrapper fails before invoking the upstream helper

#### Scenario: Session handoff

- **WHEN** greetd starts the Niri UWSM session
- **THEN** UWSM output is preserved in the journal and not displayed on the greeter VT

#### Scenario: NixOS target resolves the wrapper

- **WHEN** the NixOS-embedded Home Manager configuration is evaluated
- **THEN** the greeter-sync privilege command invokes `/run/wrappers/bin/pkexec`
- **AND** the NixOS target enables the pkexec wrapper and the polkit rule

#### Scenario: Generic-Linux target resolves the wrapper

- **WHEN** the standalone Arch Home Manager configuration is evaluated
- **THEN** the greeter-sync privilege command invokes `/usr/bin/pkexec`
