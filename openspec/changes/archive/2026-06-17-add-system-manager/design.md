## Context

This repository is currently structured as a Home Manager flake for an Arch Linux host, with all active configuration flowing through `homeConfigurations.saurabhj`. That works well for user-scoped configuration, but it leaves daemon-scoped and root-owned configuration unmanaged, including the Nix daemon's effective `nix.conf`, root-visible SSH settings, and daemon environment injection required for services like nixbuild.net.

The immediate driver is nixbuild.net access for `ssh-ng://eu.nixbuild.net`: user-scoped SSH and secret injection are insufficient when the effective actor is the Nix daemon. The repo therefore needs a first-class system-scoped configuration path that can coexist with the existing Home Manager layout without collapsing user and system responsibilities into one layer.

## Goals / Non-Goals

**Goals:**
- Add a declarative system-scoped configuration layer to this flake for the Arch host.
- Keep the repository structure understandable by mirroring the existing host/module layout where practical.
- Move daemon-facing Nix configuration to system scope so root/daemon execution sees the intended settings.
- Establish a secure path for daemon-visible nixbuild.net configuration.
- Minimize disruption to existing Home Manager modules and user services.

**Non-Goals:**
- Converting the machine to NixOS.
- Migrating every user service or user secret into system scope.
- Reworking unrelated Home Manager modules, shell configuration, or developer tooling.
- Solving every future system-level concern in this first change; the goal is to create the foundation plus the first high-value migration.

## Decisions

### Use system-manager as the system-scoped configuration layer
- **Decision:** Introduce `system-manager` as a new flake input and expose a system-level configuration output for the Arch host.
- **Rationale:** The repo already uses the Nix module model effectively through Home Manager. `system-manager` extends that same declarative model to non-NixOS system configuration, which is a better fit than ad hoc root scripts or manual `/etc` edits.
- **Alternatives considered:**
  - Manual root edits in `/etc` and `/root/.ssh`: rejected because they drift from the repo and are hard to review.
  - Systemd drop-ins managed outside the flake: rejected because they solve only one symptom and fragment ownership.
  - Keeping everything in Home Manager: rejected because daemon/root execution does not reliably see user-scoped configuration.

### Create a parallel `modules/system/` and `hosts/arch/system.nix` structure
- **Decision:** Model system-manager configuration with a host entrypoint and a `modules/system/` tree parallel to the existing Home Manager structure.
- **Rationale:** The repo already communicates ownership through `hosts/<host>/home.nix` and `modules/home/**`. A parallel system tree preserves discoverability and reduces ambiguity about what runs as the user versus what runs at system scope.
- **Alternatives considered:**
  - Embedding all system-manager config inline in `flake.nix`: rejected because it would not scale.
  - Mixing system modules into `modules/home/`: rejected because it blurs privilege boundaries.

### Move daemon-relevant Nix settings to system scope, keep user tooling in Home Manager
- **Decision:** System-level Nix daemon settings such as substituters, trusted public keys, and daemon-facing nixbuild.net access move under system-manager. User-scoped Nix packages, CLI tools, and user timers remain in Home Manager.
- **Rationale:** This aligns configuration with the process that consumes it and avoids duplicating daemon policy across user and system layers.
- **Alternatives considered:**
  - Duplicating the same Nix settings in both places: rejected because divergence would be likely.
  - Moving all Nix-related config to system scope: rejected because user tooling belongs with Home Manager.

### Use system-scoped secret or environment wiring for nixbuild.net access
- **Decision:** The implementation should provide nixbuild.net credentials in a daemon-visible way at system scope, rather than relying on user shell inheritance.
- **Rationale:** The daemon or root-owned processes may initiate the effective SSH connection, so credential delivery must not depend on an interactive user session.
- **Alternatives considered:**
  - `SendEnv` from user shell only: rejected as too fragile for daemon execution.
  - User-only SSH includes: rejected because root/daemon paths will not consume them.

## Risks / Trade-offs

- **[New system dependency]** Introducing `system-manager` increases flake complexity and adds a second configuration plane. → **Mitigation:** keep scope narrow in the first change and mirror existing structure.
- **[Ownership confusion]** Some settings may appear to belong to both Home Manager and system-manager during migration. → **Mitigation:** explicitly document which layer owns daemon policy versus user tooling, and remove migrated daemon settings from Home Manager.
- **[Secret handling complexity]** System-scoped secrets may require different key material or deployment mechanics than user-scoped sops templates. → **Mitigation:** design the implementation around daemon-visible delivery first and keep user-only secrets in Home Manager.
- **[Activation risk]** Misconfigured system-level Nix settings can disrupt builds or substituters. → **Mitigation:** migrate incrementally and validate generated system config before switch/apply.

## Migration Plan

1. Add `system-manager` to the flake inputs and expose a system configuration output for the Arch host.
2. Create `modules/system/` and `hosts/arch/system.nix` as the new system-scoped entrypoints.
3. Implement system-scoped Nix configuration in a dedicated module.
4. Move daemon-facing Nix settings out of `modules/home/nix.nix`, leaving only user-scoped Nix tools and timers.
5. Add system-scoped nixbuild.net credential/config plumbing.
6. Validate that the Home Manager and system-manager layers each own the intended responsibilities.

## Open Questions

- Whether system-scoped secret delivery should reuse sops directly or use a different root-visible mechanism.
- Whether root SSH configuration is needed in addition to daemon-visible environment/config, depending on how the final system-manager modules model the nixbuild.net connection path.
- Whether any existing user services should eventually be promoted to system scope in a follow-up change.