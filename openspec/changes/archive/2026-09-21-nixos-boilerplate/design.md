# Design — NixOS Boilerplate Skeleton

Mirrors the structure of the de-facto repo design template
(`openspec/changes/archive/2026-08-18-dendritic-cleanup-pre-nixos/design.md`):
each section states a rationale, shows the concrete shape, and where relevant
records the anti-pattern being avoided.

## 1. Composition shape

`nixosConfigurations.arch` slots into the existing host composition layer
(`modules/hosts/arch.nix`) alongside the already-present
`homeConfigurations.saurabhj` and `systemConfigs.arch`. All three read the
same typed `topology.hosts.arch` and the same lexical `inputs`; none introduce
a `specialArgs`/`extraSpecialArgs` bus (cleanup invariant, Tetens 7/8).

A `nixosAspect` helper mirrors the existing `hmAspect` and `systemAspect`
helpers (arch.nix:19-20):

```nix
hmAspect    = name: config.flake.modules.homeManager.${name};
systemAspect = name: config.flake.modules.systemManager.${name};
nixosAspect  = name: config.flake.modules.nixos.${name};   # new
```

The NixOS host is constructed from the raw host file plus the selected aspects,
identical in shape to the system-manager construction (`arch.nix:86-89`):

```nix
nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
  modules = [
    ./arch/_nixos.nix
  ] ++ map nixosAspect nixosAspects;
  specialArgs = {};   # empty — NO inputs/hostFacts bus; maintain cleanup invariant
};
```

It is exposed as `flake.nixosConfigurations.arch = nixosConfiguration`, and a
check forces full eval (see §5).

## 2. `flake.modules.nixos.*` class

`flake.modules` is a flake-parts-level option (typed
`lazyAttrsOf (lazyAttrsOf deferredModule)`, keyed class → aspect) declared by
`inputs.flake-parts.flakeModules.modules`, imported via
`modules/flake/scaffold.nix`. Because the type is `lazyAttrsOf (lazyAttrsOf …)`
— a map from arbitrary class strings to aspect maps — `nixos` is accepted as a
class string exactly as `homeManager` and `systemManager` already are. **No
type change is required**; this is not a new mechanism, just a third class key
under an already-general option. (Confirming task A8 reduces to reading
`modules/flake/scaffold.nix` + the flake-parts `modules` extra — verified: the
option type is `lazyAttrsOf (lazyAttrsOf deferredModule)`, not an enumerated
list of class literals.)

Feature modules publish NixOS aspects under the new key; e.g. a future
`modules/ssh.nix` would add `flake.modules.nixos.ssh` next to its existing
`homeManager.ssh` / `systemManager.ssh`. This change adds exactly one such
publisher: the smoke-test `foundation` aspect (§4).

## 3. Hardware-configuration.nix placement

The `hardware-configuration.nix` convention (the shape `nixos-generate-config`
emits) is adopted as the host-local raw file
`modules/hosts/arch/_hardware.nix`:

- Raw host file, `_`-prefixed so `import-tree` ignores it — the same pattern as
  the existing `_home.nix` / `_system.nix` (arch.nix host-local doubles).
- **Not a dendritic aspect.** Hardware is irreducibly per-host, so it lives as
  a host-local raw file like the other host doubles, never in `flake.modules.*`.
- **Imported directly by `_nixos.nix`** (via the module's `imports`), not
  through an aspect.

Content for this change is a **TODO stub** — `fileSystems = {};`,
`boot.loader = {};` and similar empty placeholders with a `ponytail:` comment
naming the install-day flow:

```nix
# ponytail: install-day stub. On NixOS day run
#   nixos-generate-config --root /mnt
# then hand-edit this file down to minimal (fileSystems, boot.loader.grub/systemd-boot).
```

This keeps the skeleton *evaluable* (NixOS evaluates with empty `fileSystems`)
without pretending it is *switchable*. Population is a deferred follow-up
(task C8).

## 4. Smoke-test aspect

A new feature file `modules/foundation/nixos.nix` publishes the first NixOS
aspect. The outer form matches the foundation files' published-module shape
(`_: { flake.modules.systemManager.<name> = …; }`), here under `nixos`:

```nix
_: {
  flake.modules.nixos.foundation = {
    system.stateVersion = "26.11";
    networking.hostName = "arch";
    # Placeholder bootstrap user; real user config arrives with aspect side-port.
    users.users.saurabhj = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
}
```

This is deliberately minimal: its entire point is to **prove the
`flake.modules.nixos.*` plumbing evaluates end-to-end under `nixosSystem`**.
Since it is an aspect value (not a function taking lower-level args), it cannot
read `config.topology` directly; host identity is supplied by the raw
`_nixos.nix` file, keeping host-local literals in the host layer per the
composition model. One aspect is a smoke test, not a pattern — it does not yet
warrant a canonical spec (see §7).

## 5. Eval gates

A check entry mirrors the existing `home-manager-activation` /
`system-manager-config` gates (`arch.nix:112-115`):

```nix
flake.checks.${system} = {
  # ...existing...
  nixos-system = nixosConfiguration.config.system.build.toplevel;
};
```

Binding `toplevel` forces `nixosSystem` to evaluate its full config under
`nix flake check`. Under `--no-build` this validates evaluation only — it does
**not** build the store closure, which is the intended scope (skeleton is
*evaluable*, not *switchable*).

Two verification commands gate the change:

```sh
nix flake check --no-build --no-write-lock-file   # flake gates
openspec validate --strict                        # artifact gates
```

Plus a manual eval beyond `--no-build` (task A10):

```sh
nix eval .#nixosConfigurations.arch.config.system.build.toplevel.drvPath
```

## 6. Non-goals (detailed)

Restating the out-of-scope work with rationale. Each side-port is a separate
change, not folded into this skeleton.

- **Side-port of system-manager aspects.** Each system-manager aspect needs its
  own migration analysis because the NixOS native surface differs from a
  system-manager module:
  - `boot` → `boot.loader.systemd-boot` (system-manager manipulates a Limine
    conf via `environment.etc`; NixOS owns the bootloader declaratively).
  - `network` → `networking.*` / `NetworkManager` vs the current
    systemd-resolved mDNS tweak.
  - `ssh` → `services.openssh` (currently a systemManager aspect plus HM
    client side).
  - `tailscale` → `services.tailscale` (currently dual HM/systemManager).
  - `greeter` → `services.greetd` + noctalia NixOS module.
  - `nix` → `nix.settings` (most direct mapping; system-manager side fades).
  - `nixbuild` → native NixOS remote-build config; the transitional structure
    is dropped in favor of the native module.
- **VM test harness / CI QEMU runner.** Depends on this change's eval landing
  first; strictly follow-up.
- **Bare-metal install / `_hardware.nix` population.** Install-day
  `nixos-generate-config` then hand-editing; deferred.
- **nixos-facter.** Rejected by user decision — hand-rolled from existing
  literals (`primaryUser = "saurabhj"`, `system = "x86_64-linux"`) for control
  and no new tooling.
- **User layer migration.** Home Manager stays as today; NixOS owns the system
  layer post-migration only.

## 7. Spec sync state

- `system-manager-foundation/spec.md` was already updated during the cleanup
  (its `source-change` is the archived add-system-manager change and the text
  frames system-manager as *"for non-NixOS hosts"*, naming NixOS as the target
  class). **No change needed** this change (task B2 confirms as a no-op check).
- `dendritic-module-composition/spec.md` already contracts the
  typed-`topology`/native-option model this change inherits; the NixOS class
  adds no new composition mechanism, so no edit is required.
- **No new canonical spec** for the NixOS skeleton. The single `foundation`
  aspect is a smoke test, not a pattern; spec work lands with aspect
  side-porting, when NixOS aspects accumulate into a real surface.

## 8. Deferred task inventory

Each deferred item is recorded as a non-executable checkbox in tasks.md (Group
C), not implemented here.

**System-manager aspects to side-port (each a follow-up change):**

| Current | NixOS target |
|---|---|
| `modules/foundation/network.nix` (systemManager) | `networking.*` / NetworkManager |
| `modules/foundation/boot.nix` (systemManager) | `boot.loader.systemd-boot` |
| `modules/ssh.nix` (systemManager side) | `services.openssh` |
| `modules/tailscale.nix` (systemManager side) | `services.tailscale` |
| `modules/desktop/greeter.nix` (systemManager) | `services.greetd` + noctalia |
| `modules/nix.nix` (systemManager side) | `nix.settings` (most direct) |
| `modules/nixbuild.nix` | native NixOS remote-build; drop transitional shape |

**HM-side aspects (mostly no-op on NixOS):** niri, noctalia, monique, vicinae,
portals, shell/fish/zsh, and the rest — Home Manager is class-agnostic, so no
migration needed; NixOS evaluates them through the same `homeManager` aspects.

**New work unlocked (deferred):**

- VM test harness in CI (QEMU runner booting `nixosConfigurations.arch`).
- `_hardware.nix` population via `nixos-generate-config` on install day.
