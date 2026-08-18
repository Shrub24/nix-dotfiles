# Proposal: NixOS Boilerplate Skeleton

## Summary

Introduces a minimal NixOS configuration class to the existing flake alongside
Home Manager and system-manager. Produces a `nixosConfigurations.arch` output
that evaluates cleanly under `nix flake check` without producing a
switchable bare-metal configuration. The hardware-configuration.nix convention
(handed-down from `nixos-generate-config`) is adopted as the host-local raw
file shape.

## Motivation

The dendritic repository cleanup (archived change `dendritic-cleanup-pre-nixos`)
removed the `specialArgs`/`hostFacts` anti-patterns and introduced the typed
`topology` option. The next concrete migration step is to introduce the NixOS
class itself as a typed, evaluable output — before any aspect side-porting or
bare-metal install. This unblocks: (a) QEMU VM CI harness (validate flake
end-to-end under `nixosSystem`); (b) progressive aspect side-port
(system-manager → NixOS native modules) in tracked follow-up changes;
(c) bare-metal install on NixOS day once `_hardware.nix` is populated.

## Scope

### In scope

- Add `nixosConfigurations.arch` to flake via `nixpkgs.lib.nixosSystem`.
- Add `flake.modules.nixos.<name>` infrastructure (mirror the existing
  `flake.modules.homeManager`/`flake.modules.systemManager` shapes).
- Add `modules/hosts/arch/_hardware.nix` (raw, host-local; TODO stub for
  install-day population via `nixos-generate-config`).
- Add `modules/hosts/arch/_nixos.nix` (raw, host-local; imports \_hardware.nix,
  sets hostname, base user, stateVersion).
- Wire `nixosConfigurations.arch` in `modules/hosts/arch.nix` host composition
  layer — reuses existing `topology.hosts.arch` + lexical `inputs` pattern.
- Add a `flake.checks.x86_64-linux.nixos-system` that forces NixOS eval (mirrors
  the existing `home-manager-activation` / `system-manager-config` checks).
- One NixOS aspect as smoke test: `flake.modules.nixos.foundation` — a minimal
  bootstrap aspect (stateVersion, hostname, user placeholder, nothing else).

### Out of scope (explicit non-goals)

- Side-port of system-manager aspects (network, boot, ssh, tailscale, greeter,
  nix, nixbuild) → NixOS native modules. Tracked in tasks as deferred
  follow-ups only.
- Bare-metal install / `_hardware.nix` population (install-day work).
- VM test harness / CI QEMU runner (follow-up change; requires the eval to
  land first).
- nixos-facter integration (rejected — hand-rolled for control).
- User-migration (HM stays as today; NixOS owns system layer
  post-migration only).

## User decisions

- Hand-rolled from existing literals, not `nixos-facter`.
- `hardware-configuration.nix` as `modules/hosts/arch/_hardware.nix`
  (raw, `_`-prefixed, host-local).
- No second flake — add `nixosConfigurations` to existing flake.
- Bare minimum skeleton — evaluable, not switchable.
- Aspect side-port deferred but tracked.
- No new `specialArgs`/`hostFacts` (cleanup removed those anti-patterns;
  NixOS inherits the clean topology-based shape).
