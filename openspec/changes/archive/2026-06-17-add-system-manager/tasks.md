## 1. Add system-manager foundation

- [x] 1.1 Add the `system-manager` flake input and define a system-scoped flake output for the Arch host.
  - refs: `flake.nix`, `hosts/arch/home.nix`
  - criteria: the flake exposes both the existing Home Manager output and a new system-manager output for the Arch machine
  - verify: evaluate the new flake output without removing the existing home configuration
- [x] 1.2 Create `hosts/arch/system.nix` and a new `modules/system/` import tree that mirrors the existing host/module layout.
  - refs: `hosts/arch/home.nix`, `modules/default.nix`, `modules/home/**`
  - criteria: system-scoped configuration has a dedicated entrypoint and import structure separate from Home Manager

## 2. Move daemon-scoped Nix ownership

- [x] 2.1 Create a system-scoped Nix module that manages daemon-visible Nix settings such as substituters, trusted keys, and daemon policy.
  - refs: `modules/home/nix.nix`, `openspec/changes/add-system-manager/specs/daemon-nix-config/spec.md`
  - criteria: daemon-relevant Nix configuration is declared in the system layer rather than only in Home Manager
- [x] 2.2 Refactor `modules/home/nix.nix` so it retains only user-scoped packages, tools, and user cleanup behavior.
  - refs: `modules/home/nix.nix`
  - depends: 2.1
  - criteria: Home Manager no longer owns daemon-visible Nix policy while preserving user tooling behavior

## 3. Add daemon-visible nixbuild.net access

- [x] 3.1 Implement a system-scoped path for nixbuild.net access configuration that works for daemon/root execution.
  - refs: `modules/home/remote/ssh.nix`, `modules/home/sops.nix`
  - criteria: the chosen mechanism does not depend on interactive user shell inheritance
- [x] 3.2 Define how system-scoped secret/config delivery is wired for nixbuild.net and document any required host-side setup.
  - refs: `design.md`
  - depends: 3.1
  - criteria: the implementation makes clear where the daemon-visible credential source lives and how it is applied

## 4. Validate ownership boundaries

- [x] 4.1 Verify the system-manager and Home Manager layers each own the intended responsibilities after migration.
  - refs: `proposal.md`, `design.md`
  - criteria: daemon/root concerns are system-scoped and user concerns remain user-scoped
- [x] 4.2 Run the relevant flake/OpenSpec validation commands and update documentation or comments needed for the new system entrypoint.
  - refs: `flake.nix`, `hosts/arch/system.nix`, `openspec/changes/add-system-manager/**`
  - depends: 4.1
  - verify: `openspec validate --strict` and the relevant flake evaluation checks succeed
