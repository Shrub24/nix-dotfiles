# Tasks — NixOS Boilerplate Skeleton

## Group A — Skeleton (executable in this change)

- [x] `A1.` Add `nixosAspect` helper to `modules/hosts/arch.nix` (mirror
  `hmAspect`/`systemAspect`).
- [x] `A2.` Create `modules/hosts/arch/_hardware.nix` (raw, host-local, TODO stub
  with `fileSystems = {};` etc + `ponytail:` comment naming install-day
  `nixos-generate-config` flow).
- [x] `A3.` Create `modules/hosts/arch/_nixos.nix` (raw, host-local; imports
  `_hardware.nix`; sets `system.stateVersion = "26.11"`,
  `networking.hostName = "arch"`, `users.users.saurabhj = { isNormalUser = true; extraGroups = ["wheel"]; };`).
- [x] `A4.` Create `modules/foundation/nixos.nix` (smoke-test aspect publishing
  `flake.modules.nixos.foundation` — minimal bootstrap content: stateVersion,
  hostname, user placeholder, nothing else).
- [x] `A5.` Wire `nixosConfigurations.arch` in `modules/hosts/arch.nix` via
  `inputs.nixpkgs.lib.nixosSystem { modules = [ ./arch/_nixos.nix ] ++ map nixosAspect nixosAspects; specialArgs = {}; };` — note empty `specialArgs`
  (NO `inputs`/`hostFacts` bus — maintain the cleanup invariant).
- [x] `A6.` Add `flake.checks.x86_64-linux.nixos-system = config.flake.nixosConfigurations.arch.config.system.build.toplevel;`
  in `modules/hosts/arch.nix`.
- [x] `A7.` Register `nixosAspects = [ "foundation" ];` (just the smoke test).
- [x] `A8.` Verify `flake.modules.nixos` class is accepted by the existing
  `flake.modules` option (read `modules/flake/scaffold.nix` + flake-parts
  `modules` extra first — type is `lazyAttrsOf (lazyAttrsOf deferredModule)`,
  so any class string is accepted; no enum to extend).
- [x] `A9.` Verify gates: `nix flake check --no-build --no-write-lock-file` green;
  `openspec validate --strict` green.
- [x] `A10.` Manually eval
  `nix eval .#nixosConfigurations.arch.config.system.build.toplevel.drvPath`
  to confirm NixOS eval works (not just `--no-build`).

## Group B — Documentation + deferred inventory

- [x] `B1.` Update `ARCHITECTURE.md` to mention NixOS class as target
  (composition paragraph + `hosts/arch` tree note).
- [x] `B2.` Update `openspec/specs/system-manager-foundation/spec.md` if needed
  (probably no change — spec already frames system-manager as "for non-NixOS
  hosts" and names NixOS as the target class).
- [x] `B3.` Verify the deferred aspect side-port list below (Group C) reads
  correctly as a tracking inventory.

## Group C — Deferred (explicit non-goals — checkboxes left unchecked)

Each item below is a tracking checkbox for a follow-up change. They are NOT
executed in this change; leaving `- [ ]` documents that the work remains.

- [ ] `C1.` Side-port `network` aspect → `networking.*`/NetworkManager
- [ ] `C2.` Side-port `boot` aspect → `boot.loader.systemd-boot`
- [ ] `C3.` Side-port `ssh` aspect (systemManager side) → `services.openssh`
- [ ] `C4.` Side-port `tailscale` aspect (systemManager side) → `services.tailscale`
- [ ] `C5.` Side-port `greeter` aspect (systemManager side) → `services.greetd` + noctalia
- [ ] `C6.` Side-port `nix` aspect (systemManager side) → `nix.settings`
- [ ] `C7.` Side-port `nixbuild` (or drop in favor of native NixOS remote-build)
- [ ] `C8.` Populate `_hardware.nix` via `nixos-generate-config` on install day
- [ ] `C9.` VM test harness (QEMU CI runner; follow-up change)
- [ ] `C10.` Bare-metal install

## Final Validation

- [x] `nix flake check --no-build --no-write-lock-file` passes.
- [x] `openspec validate --strict` passes.
- [ ] User confirms the skeleton evals cleanly before side-port work begins.
