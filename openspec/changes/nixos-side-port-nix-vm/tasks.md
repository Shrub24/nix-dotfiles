# Tasks - Side-Port `nix` Aspect + VM Boot Test Harness

## Group A - Side-port `nix` aspect to NixOS

- [x] `A1.` Add `flake.modules.nixos.nix` aspect to `modules/nix.nix`
  alongside the existing `homeManager.nix` / `systemManager.nix` aspects.
  Translation: `nix.settings` verbatim; `environment.etc."profile.d/nix-path.sh"`
  -> `nix.nixPath`; drop `nix.enable` (NixOS enables nix by default). Keep
  the `niks3UploadHook` post-build-hook as-is.
- [x] `A2.` Register `"nix"` in `nixosAspects` in `modules/hosts/arch.nix`
  (list grows from `[ "foundation" ]` to `[ "foundation" "nix" ]`).
- [x] `A3.` Verify `nix eval .#nixosConfigurations.arch.config.system.build.toplevel.drvPath`
  still passes - the new aspect must evaluate cleanly under `nixosSystem`.

## Group B - VM test harness

- [x] `B1.` Add `flake.checks.${system}.vm-skeleton-boot` entry in
  `modules/hosts/arch.nix` using `pkgs.testers.runNixOSTest`. The node
  config imports `map nixosAspect nixosAspects` (foundation + nix) plus
  minimal VM hardware (QEMU disk + grub, virtio_blk, headless). Asserts
  `multi-user.target` reached, `nix-daemon.service` active, `nix-store
  --version` succeeds.
- [x] `B2.` Run `nix build .#checks.x86_64-linux.vm-skeleton-boot`
  locally - the test must build and run end-to-end (QEMU boots, nix-daemon
  starts, assertions pass). Fix any test failures before committing.

## Group C - Deferred (explicit non-goals - checkboxes left unchecked)

Each item is a tracking checkbox for a follow-up change.

- [ ] `C1.` Side-port `network` aspect -> `networking.*`/NetworkManager
- [ ] `C2.` Side-port `boot` aspect -> `boot.loader.systemd-boot`
- [ ] `C3.` Side-port `ssh` aspect (systemManager side) -> `services.openssh`
- [ ] `C4.` Side-port `tailscale` aspect (systemManager side) -> `services.tailscale`
- [ ] `C5.` Side-port `greeter` aspect (systemManager side) -> `services.greetd` + noctalia
- [ ] `C6.` Side-port `nixbuild` -> native NixOS remote-build; drop transitional
- [ ] `C7.` Populate `_hardware.nix` via `nixos-generate-config` on install day
- [ ] `C8.` Wire `checks-build` CI job to run `nix flake check` (without `--no-build`)
  so the VM test boots on PRs; today the workflow uses `--no-build`.
- [ ] `C9.` Bare-metal install

## Final Validation

- [ ] `nix flake check --no-build --no-write-lock-file` passes.
- [ ] `nix build .#checks.x86_64-linux.vm-skeleton-boot` passes (QEMU boots,
  nix-daemon starts, assertions succeed).
- [ ] `openspec validate --strict` passes.
