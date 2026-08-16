## 1. Establish a safe baseline

- [x] 1.1 Record the current host-output, formatter, Statix, and Deadnix results before moving configuration.
  - refs: `flake.nix`, `hosts/arch/`, `modules/`, `pkgs/`
  - verify: `nix flake check --no-build --no-write-lock-file`; targeted formatter, Statix, and Deadnix commands
- [x] 1.2 Identify every active reference to the modules, inputs, secrets, packages, activation hooks, and documentation claims removed by this change.
  - criteria: removal candidates are classified as active, historical, generated, or stale before deletion
  - verify: scoped codebase-memory searches with coverage checks; QMD search scoped to `project-root`

## 2. Remove stale ownership and retain the minimal Pi skeleton

- [x] 2.1 Remove the dormant Bluetooth rfkill module and unused fifc and standalone nvfetcher flake inputs.
  - refs: `modules/system/bluetooth.nix`, `modules/system/default.nix`, `flake.nix`, `flake.lock`
  - criteria: no active configuration references Bluetooth rfkill, fifc, or `inputs.nvfetcher`; the remaining update command uses `pkgs.nvfetcher`
  - verify: active-reference check; `nix flake check --no-build --no-write-lock-file`
- [x] 2.2 Remove the unused custom Snip derivation, overlay/source wiring, and stale agent-tools description; verify that no managed OpenCode Snip plugin registration exists.
  - refs: `pkgs/snip/`, `pkgs/_sources/`, `nvfetcher.toml`, `flake.nix`, agent tools module, managed OpenCode configuration
  - criteria: no custom Snip derivation, generated source, package exposure, or stale agent-tools description remains; canonical OpenSpec removal deltas remain until archival
  - verify: active-reference check excluding archives/tool state; `nix flake check --no-build --no-write-lock-file`
- [x] 2.3 Remove the stale LiteLLM nvfetcher record and regenerate committed source metadata for active consumers only.
  - refs: `nvfetcher.toml`, `pkgs/_sources/generated.nix`, `pkgs/litellm/oci.nix`
  - criteria: every declared nvfetcher source is consumed by an active package; LiteLLM continues to use its OCI source path
  - verify: `nix run .#nvfetcher-update`; targeted evaluation of package overlay and LiteLLM configuration
- [x] 2.4 Replace the legacy Pi module with the disabled-by-default package/freeform-settings skeleton; remove Pi-only schemas, dependencies, Telegram bootstrap, and secret lifecycle.
  - refs: Pi module, `hosts/arch/home.nix`, `modules/home/sops.nix`, `secrets/pi-secrets.yaml`, `flake.nix`
  - criteria: disabled Pi adds no package, runtime file, secret, or activation hook; enabled Pi installs its selected package and renders freeform settings
  - verify: Home Manager evaluation with Pi disabled and a targeted temporary evaluation with Pi enabled
- [x] 2.5 Remove completed migration activation hooks and replace Docs MCP/LiteLLM config-change orchestration with systemd restart triggers; retain only the LiteLLM OCI image-load activation.
  - refs: Docs MCP module, LiteLLM module, Posting integration, host activation hooks
  - criteria: service restarts are systemd-managed; no completed cleanup, Telegram bootstrap, or best-effort Posting sync runs at activation
  - verify: inspect rendered user service definitions and evaluate the Home Manager activation package

## 3. Establish root-owned Nixbuild secrets

- [x] 3.1 Create and protect the persistent root-owned sops age identity, add its recipient to the Nixbuild encrypted secret, and verify system-manager can decrypt it.
  - refs: `.sops.yaml`, `secrets/nixbuild.yaml`, `hosts/arch/system.nix`
  - criteria: the root key is under `/var/lib/sops-nix/`, readable only by root; encrypted Nixbuild data has the root recipient
  - notes: the key creation is a one-time host operation; do not use `sops.age.generateKey` under system-manager
  - verify: `sops updatekeys secrets/nixbuild.yaml`; system-manager evaluation
- [x] 3.2 Import sops-nix at system scope and render the Nixbuild environment file in `/run/secrets` with root-only ownership.
  - refs: system-manager feature/module, `secrets/nixbuild.yaml`
  - criteria: system sops uses `useSystemdActivation = true`; no root service consumes a Home Manager-generated secret or a user-controlled path
  - verify: evaluate system-manager configuration and inspect rendered service/secret paths
- [x] 3.3 Order and restart `nix-daemon.service` declaratively when the Nixbuild credential changes, then delete the old cross-scope Home Manager template and `/etc` symlink.
  - refs: Nixbuild system aspect, Home Manager sops module, `environment.etc`
  - criteria: daemon startup waits for secret installation and credential rotation triggers a daemon restart
  - verify: system-manager activation-package evaluation and systemd unit dependency inspection

## 4. Convert configuration to dendritic feature aspects

- [x] 4.1 Create the dedicated flake-module discovery root and add `import-tree`; convert only conforming flake-parts modules into that root.
  - refs: `flake.nix`, design D1-D2
  - criteria: discovery does not scan raw Home Manager/system-manager modules, package functions, generated sources, or disabled support files
  - verify: flake evaluation with discovery enabled
- [x] 4.2 Extract local overlay construction into `pkgs/default.nix` and move each package-specific override, including Keypeek, to its package boundary.
  - refs: `flake.nix`, `pkgs/`
  - criteria: `flake.nix` no longer defines package implementation; overlay consumers preserve package names and behavior
  - verify: package overlay evaluation and supported host-output evaluation
- [x] 4.3 Convert core Nix, secrets, shell, development tools, remote access, agent, and service features into published Home Manager and/or system-manager aspects.
  - refs: current `modules/home/`, `modules/system/`, `lib/`, `policy/`
  - criteria: each feature owns its scope-specific behavior; reusable aspects contain no duplicated Arch identity, absolute home path, or remote-host facts
  - delegate: CoderAgent implementation; CodeReviewer review before task completion
  - verify: evaluate each converted aspect through the Arch host composition
- [x] 4.4 Split the desktop domain into independently selectable niri, Noctalia, Monique, and greeter aspects without changing upstream package ownership or Monique's sole monitor authority.
  - refs: current niri, greeter, and desktop integration modules; `niri.config.kdl.imperative-backup`
  - criteria: no custom Noctalia/Monique package is introduced; mutable Monique monitor state remains outside Git; only selected desktop aspects contribute behavior
  - delegate: CoderAgent implementation; CodeReviewer review before task completion
  - verify: evaluate the Arch Home Manager and system-manager outputs; inspect generated niri and user-service configuration
- [x] 4.5 Move identity, derived paths, architecture, and remote-machine facts to one Arch host definition; compose only selected published aspects into Home Manager and system-manager outputs.
  - refs: `hosts/arch/`, `flake.nix`, feature aspects
  - criteria: host outputs have explicit aspect lists; dormant aspects do not alter either output; reusable features do not duplicate host literals
  - verify: `nix flake show`; Home Manager activation and system-manager configuration evaluation
- [x] 4.6 Remove obsolete class-tree registries and transition-only imports after all selected aspects evaluate through the host.
  - refs: legacy `modules/default.nix`, group `default.nix` files, legacy class directories
  - criteria: no central registry remains; every remaining discovered module satisfies the flake-module contract
  - verify: graph/reference audit; `nix flake check --no-build --no-write-lock-file`

## 5. Add the canonical validation workflow

- [x] 5.1 Add `numtide/treefmt-nix` and define the flake formatter and formatting check for maintained source.
  - refs: `flake.nix`, formatter configuration
  - criteria: `nix fmt` and its check use the same treefmt configuration; only generated, encrypted, or tool-state paths are excluded
  - verify: `nix fmt -- --fail-on-change`
- [x] 5.2 Expose Statix, Deadnix, Home Manager activation evaluation, and system-manager evaluation as non-mutating flake checks; fix all live findings.
  - refs: flake check definitions, all formatted/linted Nix source
  - criteria: check failures are actionable; no source suppression hides a live finding without a documented generated-source reason
  - delegate: BuildAgent validation; CodeReviewer review before task completion
  - verify: `nix flake check --no-build --no-write-lock-file`
- [x] 5.3 Add Lefthook pre-commit and pre-push hooks that reuse the canonical formatter/lint and no-build flake checks.
  - refs: `lefthook.yml`, flake dev shell/package exposure
  - criteria: pre-commit is scoped and fast; pre-push runs the canonical non-mutating flake check; no duplicate validation implementation is introduced
  - verify: install hooks and run both hook commands against the worktree
- [x] 5.4 Add a minimal GitHub Actions validation workflow using immutable action revisions and the same canonical flake check.
  - refs: `.github/workflows/`, `renovate.json`
  - criteria: pull requests exercise the local validation contract; Renovate can update workflow actions
  - delegate: OpenDevopsSpecialist implementation/review
  - verify: workflow syntax/action pin audit and local command parity check

## 6. Reconcile documentation

- [x] 6.1 Capture post-migration source-of-truth facts before writing prose: flake output names, discovery root, aspect names, host fact ownership, root-secret paths, overlay location, service lifecycle, and canonical check command.
  - refs: `flake.nix`, `hosts/arch/`, feature discovery root, `pkgs/`, `secrets/`
  - criteria: documentation facts are verified against migrated output rather than pre-migration files
  - delegate: DocWriter implementation
  - verify: `nix flake show`; `nix flake check --no-write-lock-file`
- [x] 6.2 Rewrite `README.md` for setup and operator commands only; remove filesystem inventories, module-authoring instructions, speculative roadmap content, and duplicated architecture rationale.
  - refs: `README.md`
  - criteria: documented commands are executed successfully; README points architecture readers to `ARCHITECTURE.md`
  - delegate: DocWriter implementation
  - verify: execute every documented command once
- [x] 6.3 Rewrite `ARCHITECTURE.md` around discovery, published aspects, explicit host composition, privilege boundaries, root and user secret ownership, service lifecycle, and retained design rationale.
  - refs: `ARCHITECTURE.md`, canonical `openspec/specs/`
  - criteria: no filesystem inventory remains; behavioral claims resolve to a canonical spec or are durable rationale
  - delegate: DocWriter implementation
  - verify: cross-check every path, aspect, secret, service, and port against migrated configuration
- [x] 6.4 Update `docs/web-services-catalog.md` for migrated module paths and repair its archived-spec link without changing the catalog contract.
  - refs: `docs/web-services-catalog.md`, web-service catalog spec
  - criteria: all relative links resolve and documented ports/outputs match the preserved catalog
  - delegate: DocWriter implementation
  - verify: link check and catalog-output inspection
- [x] 6.5 Delete `STRUCTURE.md` and remove all maintained references to it and retired integrations.
  - refs: `STRUCTURE.md`, `README.md`, `ARCHITECTURE.md`, `docs/`
  - criteria: maintained documentation names no Snip, fifc, standalone nvfetcher input, Pi Telegram, Bluetooth rfkill, Bifrost, or `STRUCTURE.md`
  - verify: QMD scoped removal-gate search excluding archives and tool state
- [x] 6.6 Run a documentation review for cross-document consistency, canonical-spec alignment, link integrity, command accuracy, and removal gates.
  - delegate: DocWriter review
  - verify: QMD project-root audit, link checks, documented-command execution, and `nix flake check --no-write-lock-file`

## 7. Reconcile and validate the change

- [x] 7.1 Reconcile moved paths and behavior against this change's proposal, design, and delta specs; update artifacts if implementation revealed valid drift.
  - refs: `proposal.md`, `design.md`, `specs/`
  - criteria: every requirement has an implemented and verified owner; no unrelated active OpenSpec change is archived or altered
  - delegate: CodeReviewer review
- [x] 7.2 Run the final formatter, lint, flake, host-output, hook, documentation, and strict OpenSpec validation suite.
  - verify: `nix fmt -- --fail-on-change`; Statix; Deadnix; `nix flake check --no-build --no-write-lock-file`; Home Manager activation evaluation; system-manager configuration evaluation; Lefthook; `openspec validate standardize-dendritic-nix-architecture --type change --strict`
