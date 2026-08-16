## Why

The repository has grown feature modules across flake wiring, Home Manager, system-manager, packages, host facts, activation hooks, automation, and duplicated documentation without a consistent ownership model. Converting these concerns to explicit dendritic feature modules will make composition, privilege boundaries, source ownership, and validation declarative while removing stale integrations and migration residue.

## What Changes

- **BREAKING** Reorganize the flake around dendritic feature modules that publish Home Manager and system-manager aspects, with hosts explicitly selecting the aspects they use.
- Add scoped `import-tree` discovery only after every scanned file is a flake-parts module; keep class-specific modules out of the discovery root.
- Separate the desktop domain into niri, Noctalia, Monique, and greeter aspects without introducing custom packages for upstream-provided software.
- Move custom package registration and package-specific overrides out of `flake.nix` and keep host-specific facts in host composition.
- Move the Nixbuild credential from Home Manager to root-owned system-manager sops-nix state and declaratively restart `nix-daemon` on rotation.
- Replace service-orchestration activation hooks with systemd restart triggers where the service manager already models the lifecycle; retain the LiteLLM OCI image-load activation because it installs required container state.
- Reduce Pi to a small disabled-by-default package/settings skeleton and remove stale version-specific integrations, Telegram bootstrap, and Pi-only secrets.
- Remove dormant or stale Bluetooth, fifc, nvfetcher-input, custom Snip package/source, LiteLLM-source, and completed migration wiring; the already-absent OpenCode Snip registration is verified rather than removed.
- Add treefmt-nix, Statix, Deadnix, Lefthook, and a minimal GitHub Actions validation lane with one canonical command path.
- Reconcile maintained documentation with the implemented system and delete the duplicated `STRUCTURE.md` inventory.

## Capabilities

### New Capabilities

- `dendritic-module-composition`: Feature-owned flake-parts modules publish class-specific aspects which hosts compose explicitly without accidental activation.
- `pi-agent-skeleton`: Pi retains only stable package and freeform settings wiring for future re-enablement.
- `repository-validation`: Formatting, linting, flake evaluation, local hooks, and CI share declarative repository checks.

### Modified Capabilities

- `system-manager-foundation`: System and Home Manager aspects are published and composed through explicit dendritic class boundaries.
- `daemon-nix-config`: Nixbuild credentials become root-owned system secrets with declarative daemon ordering and restart behavior.
- `nvfetcher-package-sources`: nvfetcher owns only source metadata still consumed by active custom packages.
- `snip-package`: Remove the unused custom Snip package now that the original version-lag rationale no longer holds.
- `opencode-snip-integration`: Remove the inactive OpenCode Snip plugin contract together with the unused CLI package.

## Impact

- Broad file movement under `modules/`, `hosts/`, and `pkgs/`, plus simplified `flake.nix` wiring.
- New flake inputs for `import-tree` and `treefmt-nix`; removal of dead `fifc`, standalone `nvfetcher`, and Snip source wiring.
- Root-owned sops age key and Nixbuild credential lifecycle under system-manager.
- Home Manager and system-manager output construction changes without changing the supported Arch host or its intended active services.
- New Lefthook configuration and GitHub Actions workflow; Renovate remains the update owner for flake inputs and workflow actions.
- Maintained documentation becomes `README.md`, `ARCHITECTURE.md`, OpenSpec specs, and focused generated/service documentation; `STRUCTURE.md` is removed.
