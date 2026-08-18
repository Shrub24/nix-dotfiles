# Proposal: Side-Port `nix` Aspect + VM Boot Test Harness

## Summary

Side-ports the `nix` system-manager aspect to a native NixOS aspect
(`flake.modules.nixos.nix`) and adds a minimal QEMU VM test harness in CI that
boots `nixosConfigurations.arch`'s aspect composition and asserts the
`nix-daemon` reaches `multi-user.target`. Together these prove the
side-port pattern and provide a CI gate that catches regressions before
bare-metal install day.

## Motivation

The `nixos-boilerplate` skeleton (active change) introduces
`nixosConfigurations.arch` with a single smoke-test aspect (`foundation`).
Two concrete next steps unlock real migration work:

1. **Prove the side-port pattern end-to-end** with the most direct aspect
   available. `modules/nix.nix` is that aspect: on NixOS, `nix.settings` is
   identical to the system-manager surface, and `nix.nixPath` replaces the
   custom `environment.etc."profile.d/nix-path.sh"` shim. No translation
   ambiguity, no behavior drift - just a third aspect value next to the
   existing `homeManager.nix` / `systemManager.nix` pair.

2. **Add a CI gate that boots the system in a VM.** `nix flake check
   --no-build` evaluates the config tree but does not boot it. A
   `runNixOSTest`-based harness runs QEMU, reaches `multi-user.target`, and
   asserts the side-ported `nix-daemon` starts - catching module-system
   conflicts that eval-only misses (e.g. a unit wanting a path that doesn't
   exist on NixOS, a `mkIf` that turns false under NixOS, a circular
   `systemd` dependency).

## Scope

### In scope

- Add `flake.modules.nixos.nix` aspect in `modules/nix.nix` - the NixOS-native
  equivalent of the `systemManager.nix` aspect. `nix.settings` translates
  verbatim; `environment.etc."profile.d/nix-path.sh"` becomes `nix.nixPath`;
  `nix.enable` is dropped (NixOS enables nix by default).
- Register `"nix"` in `nixosAspects` in `modules/hosts/arch.nix` (list grows
  from `[ "foundation" ]` to `[ "foundation" "nix" ]`).
- Add `flake.checks.${system}.vm-skeleton-boot` in `modules/hosts/arch.nix`
  using `pkgs.testers.runNixOSTest`. Boots a VM that imports the same aspects
  as `nixosConfigurations.arch` (foundation + nix) plus minimal VM hardware
  (no `_hardware.nix` - VM uses QEMU disk + grub). Asserts `nix-daemon`
  reaches active state and `nix-store --version` runs.

### Out of scope (explicit non-goals)

- Side-port of the remaining 6 system-manager aspects (network, boot, ssh,
  tailscale, greeter, nixbuild). Each is a separate change with its own
  translation analysis. Tracked in `tasks.md` Group C.
- The `post-build-hook` niks3 wiring stays as-is in the side-ported aspect
  (the niks3 work is deferred per user direction; the hook fires only on
  local builds and references `/run/user/1000/...` which is valid on a
  single-user NixOS desktop where builds happen while logged in).
- VM hardware-configuration population (install-day `nixos-generate-config`
  work).
- Bare-metal install.

## User decisions

- **Side-port choice: `nix`** - the most direct mapping per the
  `nixos-boilerplate` design (§6 of that change).
- **VM harness scope: boot + nix-daemon assertion only** - the skeleton has
  no other services to test. As aspects side-port, the test grows.
- **VM test hardware: standalone module** - reuses the aspects list but
  replaces `_hardware.nix`/`_nixos.nix` with QEMU-friendly values in the test
  node itself (avoids the placeholder-root-fs conflict).
- **No new `specialArgs`/`hostFacts` bus** - cleanup invariant maintained.

## Validation

- `nix flake check` (no `--no-build` here) builds and runs the new VM test
  gate from end to end - this is the whole point of the harness.
- `nix eval .#nixosConfigurations.arch.config.system.build.toplevel.drvPath`
  still passes.
- `openspec validate --strict` passes.
