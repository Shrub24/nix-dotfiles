## 1. Primary-user topology

- [x] 1.1 Change `topology.hosts.<host>.primaryUser` to a typed `{ name; uid; }` submodule and declare the Arch account once.
  - refs: `modules/policy/topology.nix`, `modules/hosts/arch.nix`
  - criteria: The topology option rejects missing/invalid name or UID values.
  - delegate: `CoderAgent`
  - verify: `nix flake check --no-build --no-write-lock-file`
- [x] 1.2 Derive Home Manager, NixOS, system-manager, VM and raw host-module identity wiring from the topology value without `specialArgs`.
  - refs: `modules/hosts/arch.nix`, `modules/hosts/arch/_home.nix`, `modules/hosts/arch/_nixos.nix`, `modules/hosts/arch/_hardware.nix`, `modules/foundation/nixos.nix`
  - criteria: Exactly one maintained runtime declaration contains the account name and UID.
  - delegate: `CoderAgent`
  - verify: Exhaustive literal search plus all three configuration evaluations.

## 2. Feature identity consumers

- [x] 2.1 Replace feature-local username and UID literals with typed topology reads closed over into the inner modules.
  - refs: `modules/desktop/greeter.nix`, `modules/desktop/noctalia.nix`, `modules/nix.nix`, `modules/syncthing.nix`, `modules/desktop-services.nix`
  - criteria: Reusable feature aspects contain no Arch account-name or UID literal.
  - delegate: `CoderAgent`
  - verify: Exhaustive literal search and `nix flake check --no-build --no-write-lock-file`.

## 3. Feature-local filesystem bootstrap

- [x] 3.1 Seed WezTerm's mutable theme through Home Manager user tmpfiles without overwriting an existing file.
  - refs: `modules/shell/wezterm.nix`, `specs/filesystem-bootstrap/spec.md`
  - criteria: A fresh home receives the tracked TOML; a pre-existing TOML remains mutable and unchanged.
  - delegate: `CoderAgent`
  - verify: Evaluate the HM activation and inspect the generated user tmpfiles rule.
- [x] 3.2 Seed Noctalia's mutable wallpaper directory from Nixpkgs artwork and point the default setting at the seeded file.
  - refs: `modules/desktop/noctalia.nix`, `specs/filesystem-bootstrap/spec.md`
  - criteria: No binary wallpaper is added to the repository and an existing user wallpaper is not replaced.
  - delegate: `CoderAgent`
  - verify: Evaluate the HM activation and inspect the generated user tmpfiles rule.
- [x] 3.3 Declare Posting's mutable data directory in the LiteLLM Home Manager aspect.
  - refs: `modules/agents/litellm/_hm.nix`
  - criteria: `litellm-sync-posting` has an existing parent directory on first use.
  - delegate: `CoderAgent`
  - verify: Evaluate the HM activation and inspect the generated user tmpfiles rule.

## 4. First-switch regression gate

- [x] 4.1 Evaluate the final Home Manager activation and inspect the combined generated user tmpfiles declarations.
  - refs: `specs/filesystem-bootstrap/spec.md`
  - criteria: Required paths, modes and seed sources are present with no competing root owner.
  - verify: `nix eval .#homeConfigurations.saurabhj.config.systemd.user.tmpfiles.rules`
- [x] 4.2 Review the final diff for ownership regressions, duplicated literals, and competing tmpfiles/native-module owners.
  - delegate: `CodeReviewer`
  - verify: No unresolved high- or medium-severity findings.
- [x] 4.3 Run repository and OpenSpec validation.
  - verify: `just --fmt --check`; `nix flake check --no-build --no-write-lock-file`; `openspec validate --all --strict`.
