## Context

See `proposal.md` for motivation and `specs/` for behavioral contracts. The flake currently combines input declarations, package overlay construction, host output construction, and cross-cutting feature wiring. Home Manager and system-manager modules live in separate import trees, but feature ownership is split across those trees and hosts receive the complete module set before options disable unwanted features.

The migration must preserve one Arch host, Home Manager, system-manager on non-NixOS, sops-nix, the patched LiteLLM OCI lifecycle, and the current web-service catalog contract. `import-tree` can discover flake-parts modules but must not scan raw class-specific modules. Home Manager's module class is `homeManager`; system-manager does not currently provide equivalent class validation.

## Goals / Non-Goals

**Goals:**

- Let each feature own its inputs, packages, Home Manager aspect, system-manager aspect, and policy near one another.
- Make host composition the explicit authority for active features and host-specific facts.
- Keep `flake.nix` as a small bootstrap for inputs and discovered flake modules.
- Use native Nix/module/systemd mechanisms before activation scripts.
- Establish one validation contract for local use, hooks, and CI.
- Delete stale implementations and documentation rather than preserving compatibility scaffolding.

**Non-Goals:**

- Add another host, NixOS support, deployment framework, secrets backend, task runner, or general constants library.
- Redesign the nvfetcher versus nix-update policy; only remove unconsumed nvfetcher sources and the unused standalone input.
- Rework LiteLLM OCI packaging or the web-service catalog beyond ownership-preserving moves.
- Archive or reconcile unrelated active OpenSpec changes.

## Decisions

### D1: Publish feature aspects through flake-parts

Each discovered file will be a flake-parts module. A feature may publish `flake.modules.homeManager.<name>` and `flake.modules.systemManager.<name>` aspects, plus feature-owned overlays or packages when required. Host construction imports named aspects explicitly.

This is the intended dendritic model: filesystem discovery handles registration, while host composition controls activation. It replaces central `default.nix` import registries and avoids passing the complete `inputs` attrset through every class-specific module.

**Alternatives considered:** Keep the current explicit class trees. This is simpler locally but retains split feature ownership and central import maintenance. Import raw Home Manager modules recursively. Rejected because discovery would become activation and dormant files could alter hosts accidentally.

### D2: Scope `import-tree` to conforming flake modules

`import-tree` will scan one dedicated flake-module root only after its contents have been converted. Raw package functions, generated sources, OpenSpec artifacts, and direct Home Manager/system-manager modules remain outside that scan.

The migration will not rely on underscore markers at the scan root to exclude arbitrary files. Structural separation is easier to inspect and avoids the known first-segment exclusion edge case.

**Alternative considered:** Continue a manually maintained flake-parts imports list. Safe, but it preserves the registry the dendritic conversion is intended to remove.

### D3: Organize by feature domain, not module class

The flake-module root will group cohesive domains such as desktop, agents, shell, remote, and system foundation. The desktop domain will expose separate niri, Noctalia, Monique, and greeter aspects. Noctalia and Monique remain upstream packages; the repository owns integration modules, not duplicate derivations.

Package recipes remain under `pkgs/`. `pkgs/default.nix` owns the local overlay, while package-specific overrides such as Keypeek live with the package boundary. Feature modules reference published packages instead of defining derivations inline.

**Alternative considered:** Preserve top-level `home/` and `system/` directories. This keeps class boundaries visible but defeats feature-local ownership. Published aspect names retain the privilege boundary without class-first folders.

### D4: Hosts own facts and select aspects

The Arch host will define identity, architecture, home directory, repository-relative paths, and shared remote-machine data once. Its Home Manager and system-manager outputs will import only named aspects needed by that host.

Paths derivable from the flake source or `home.homeDirectory` will be derived rather than passed as hardcoded global `specialArgs`. Small shared host data may be passed directly; no generic constants framework will be introduced.

### D5: System-manager owns the Nixbuild secret end to end

System-manager will import the sops-nix NixOS module, use systemd activation, and render the Nixbuild environment file under `/run/secrets` as `root:root` mode `0400`. `nix-daemon.service` will order after secret installation and restart through `restartUnits` when the credential changes.

A pre-generated root-owned age key under `/var/lib/sops-nix/` will decrypt system secrets. Automatic age-key generation is not used because that activation path is unsupported in system-manager.

**Alternative considered:** Continue exposing a Home Manager-rendered secret to the root daemon. Rejected because it crosses ownership boundaries and has no reliable boot ordering.

### D6: Prefer systemd restart triggers over activation orchestration

Generated config and secret paths will participate in user-service restart triggers for Docs MCP and LiteLLM. Completed migration cleanup, Pi Telegram bootstrap, and best-effort Posting synchronization will leave activation.

The LiteLLM OCI image-load activation remains because it installs persistent container image state before service startup and prevents the known repeated-`podman load` restart loop. It is not equivalent to service restart orchestration.

### D7: Keep only a stable Pi skeleton

Pi will retain `enable`, `package`, and freeform `settings` options, with package installation and settings-file rendering guarded by `enable`. The host keeps it disabled. Version-specific extension schemas, auxiliary runtime dependencies, Telegram activation, and Pi-only secrets will be deleted.

**Alternative considered:** Delete Pi entirely and rebuild later. The input is already retained for other tools, and a tiny package/settings module preserves useful wiring without carrying stale APIs.

### D8: Delete stale source and migration ownership

The dormant Bluetooth module, unused fifc input, unused standalone nvfetcher input, custom Snip package/source, stale LiteLLM nvfetcher source, and completed migration hooks will be removed. The OpenCode Snip registration is already absent, so it is verified rather than removed; its canonical removal delta remains until archive. nvfetcher remains for active consumers only; its broader replacement is deferred.

The custom Snip derivation is not replaced because no active module installs it. If Snip is deliberately reintroduced, the nixpkgs package is the default.

### D9: Use treefmt-nix as the validation frontend

`numtide/treefmt-nix` will define the flake formatter and formatting check. Statix and Deadnix remain explicit checks. The supported Home Manager activation package and system-manager configuration will be evaluated through flake checks.

Lefthook will run fast formatting/lint checks at pre-commit and the canonical no-build flake check at pre-push. GitHub Actions will run the same flake check with immutable action revisions. Renovate remains responsible for action and flake-input updates.

The homelab's useful pattern is its small Lefthook/CI workflow; its plain `treefmt.toml` and unenforced Statix setup are not copied because this repository explicitly chose treefmt-nix and complete lint enforcement.

### D10: Keep one durable architecture document

`README.md` will cover setup and operator commands. `ARCHITECTURE.md` will describe durable boundaries and rationale. Canonical OpenSpec specs will define behavior. `STRUCTURE.md` will be deleted because it duplicates a filesystem inventory and has repeatedly diverged from implementation.

## Risks / Trade-offs

- **[Large rename obscures behavior changes]** → Migrate by domain, evaluate both host outputs after each domain, and separate mechanical moves from semantic cleanup in reviewable task groups.
- **[Import discovery accidentally evaluates an incompatible file]** → Introduce `import-tree` only after the dedicated scan root contains conforming flake-parts modules and add a flake evaluation check.
- **[System-manager lacks class validation]** → Use explicit `flake.modules.systemManager` naming and validate by constructing the real system-manager output.
- **[Root sops key is absent during first switch]** → Document and verify the one-time root key creation and recipient update before applying the system secret change.
- **[Deleting stale integrations removes an unnoticed workflow]** → Confirm active references before deletion; all named candidates are currently dormant or unconsumed.
- **[Pre-push validation is slower than current workflow]** → Keep pre-commit checks scoped and fast; reserve full no-build flake validation for pre-push and CI.
- **[Concurrent active changes touch moved paths]** → Reconcile changes against the new paths before implementation and do not archive unrelated changes as part of this migration.

## Migration Plan

1. Record a clean evaluation baseline and remove stale inputs, packages, sources, Pi configuration, and completed hooks while paths are still familiar.
1. Add the root sops recipient and move the Nixbuild secret/service relationship into system-manager; verify daemon ordering and both host outputs.
1. Extract the package overlay and package overrides from `flake.nix`.
1. Convert feature domains to flake-parts modules that publish named aspects, keeping explicit imports during the transition.
1. Convert host construction to explicit aspect selection, then enable scoped `import-tree` discovery and remove obsolete import registries.
1. Add treefmt-nix checks, Statix, Deadnix, Lefthook, and CI; fix all live violations.
1. Reconcile README and architecture documentation, delete `STRUCTURE.md`, and run strict OpenSpec plus Nix validation.

Rollback is by task group: keep host outputs evaluable at each boundary so the last domain or discovery conversion can be reverted without restoring deleted stale integrations. The root secret migration should be reverted as a unit with its sops recipient and daemon wiring.
