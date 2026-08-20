# Design - Side-Port `nix` Aspect + VM Boot Test Harness

Mirrors the structure of `openspec/changes/nixos-boilerplate/design.md`.

## 1. Side-port shape

`modules/nix.nix` already publishes `homeManager.nix` and
`systemManager.nix` aspects from one file. A third value -
`flake.modules.nixos.nix` - is added in the same file, following the
feature-crossing-classes pattern (the dendritic skill's "one file per
feature, multiple values when the feature spans classes").

```nix
_: {
  flake.modules.homeManager.nix = { ... }: { ... };     # unchanged
  flake.modules.systemManager.nix = { ... }: { ... };  # unchanged (Arch still uses it)
  flake.modules.nixos.nix = { pkgs, lib, ... }: let
    primaryUser = "saurabhj";
    uid = 1000;
    niks3UploadHook = pkgs.writeShellScriptBin "niks3-upload-hook" ''
      exec ${lib.getExe' pkgs.niks3-hook "niks3-hook"} send --socket /run/user/${toString uid}/niks3-upload-to-cache.sock
    '';
  in {
    nix.settings = { ... };  # IDENTICAL to systemManager aspect
    nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];  # NixOS-native; replaces environment.etc."profile.d/nix-path.sh"
    # nix.enable = true is dropped - NixOS enables nix by default.
  };
}
```

**Translation table** (systemManager -> NixOS):

| systemManager aspect | NixOS aspect | Notes |
|---|---|---|
| `nix.enable = true` | (removed) | NixOS enables nix by default; the option is system-manager-specific. |
| `nix.settings = { ... }` | `nix.settings = { ... }` | Identical option name and shape on NixOS. Verbatim copy. |
| `environment.etc."profile.d/nix-path.sh".text = "export NIX_PATH=..."` | `nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];` | NixOS owns `NIX_PATH` via `nix.nixPath`; the etc shim is system-manager's workaround for the lack of a native option. |
| `niks3UploadHook` (post-build-hook) | `niks3UploadHook` (post-build-hook) | Identical; references `/run/user/1000/...` which is valid on single-user NixOS desktop where builds happen while logged in. |

**What stays the same:** the `homeManager.nix` aspect (user-side tooling,
sops templates, nh-clean timer, allowUnfreePredicate) is class-agnostic -
HM evaluates the same on NixOS.

## 2. VM test harness shape

A new `flake.checks.${system}.vm-skeleton-boot` entry uses
`pkgs.testers.runNixOSTest` (the modern `nixosTest`). It boots a QEMU VM
that imports the same aspects as `nixosConfigurations.arch` (foundation +
nix) plus minimal VM hardware.

```nix
# modules/hosts/arch.nix (excerpt)
flake.checks.${system}.vm-skeleton-boot =
  pkgs.testers.runNixOSTest {
    name = "vm-skeleton-boot";
    nodes.arch = { ... }: {
      # Same aspects as nixosConfigurations.arch - this is the test's whole point.
      imports = map nixosAspect nixosAspects;
      # Host-local literals that _nixos.nix would have set:
      system.stateVersion = "26.11";
      networking.hostName = "arch";
      nixpkgs.hostPlatform = system;
      users.users.${primaryUser} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
      # VM hardware - replaces _hardware.nix:
      fileSystems."/" = {
        device = "/dev/vda";
        fsType = "ext4";
        autoFormat = true;
      };
      boot.loader.grub.device = "/dev/vda";
      boot.initrd.availableKernelModules = [ "virtio_blk" ];
      # Headless QEMU - no graphics, no serial-named mutter, no login prompt:
      virtualisation.graphics = false;
      # Boot fast - QEMU kernel + initrd only:
      boot.initrd.kernelModules = [ "virtio_blk" ];
    };
    testScript = ''
      arch.start()
      arch.wait_for_unit("multi-user.target")
      arch.wait_for_unit("nix-daemon.service")
      arch.succeed("nix-store --version")
    '';
  };
```

**Why not reuse `_hardware.nix` / `_nixos.nix` directly?**

`_hardware.nix` has placeholder `fileSystems."/" = { device = ...; };` +
`boot.loader.systemd-boot.enable = true;` - both fail in a QEMU VM (the
disk doesn't exist; systemd-boot needs UEFI firmware which the test VM
doesn't use). Rather than fight `mkForce` overrides, the test node defines
its own hardware - clearer, smaller, and matches the standard NixOS test
pattern.

`_nixos.nix` would otherwise work but it imports `_hardware.nix`. Skipping
both and re-declaring `stateVersion`/`hostname`/`primaryUser` in the test
node keeps it self-contained.

## 3. CI behavior

`nix flake check` (without `--no-build`) builds and runs every
`flake.checks.*` entry, including the new `vm-skeleton-boot` derivation.
`runNixOSTest` produces a script that:

1. Builds a QEMU VM image from the node config.
1. Boots it.
1. Runs the `testScript`.
1. Exits 0 on success, non-zero on failure.

This adds ~30-60 seconds to a full `nix flake check` run. Locally,
operators can skip with `--no-build` for fast eval-only checks. CI runs
the full check (the `.github/workflows/validate.yml` workflow uses
`--no-build` today; the `checks-build` job added in
`dendritic-cleanup-pre-nixos` is the place to add a full-checks job that
boots the VM - but that wiring is out of scope here; the gate just needs
to be evaluable and runnable locally).

## 4. Anti-patterns avoided

- **No `specialArgs`/`hostFacts` bus** - the test node uses lexical
  closure (it captures `nixosAspect`, `nixosAspects`, `primaryUser`,
  `system` from the outer scope, exactly as `nixosConfigurations.arch`
  does).
- **No duplicate literals** - `primaryUser`, `system`, `nixosAspects` are
  the same values used by `nixosConfigurations.arch`; the test
  reuses them via closure, not re-declares.
- **No new dendritic aspect for hardware** - the test's hardware config
  is local to the test node; it's not a `flake.modules.nixos.*` value.

## 5. Spec sync state

- No new canonical spec - this change adds one aspect and one check; the
  pattern is established by `nixos-boilerplate`'s foundation aspect and
  the existing `home-manager-activation` / `system-manager-config`
  checks. Spec work lands when NixOS aspects accumulate into a real
  surface.
- `system-manager-foundation/spec.md` already frames system-manager as
  "for non-NixOS hosts" - no change.

## 6. Deferred side-port inventory

Tracked in `tasks.md` Group C. Each entry is a follow-up change:

| Current systemManager aspect | NixOS target | Notes |
|---|---|---|
| `network` | `networking.*` / NetworkManager | Resolution choice: NetworkManager vs systemd-networkd; mDNS tweak. |
| `boot` | `boot.loader.systemd-boot` | Limine conf path via environment.etc -> native boot.loader. |
| `ssh` | `services.openssh` | HM side stays; systemManager side ports. |
| `tailscale` | `services.tailscale` | HM side stays; systemManager side ports. |
| `greeter` | `services.greetd` + noctalia | Noctalia NixOS module wiring. |
| `nixbuild` | native NixOS remote-build; drop transitional | Pure simplification. |

Plus install-day work: `_hardware.nix` population via `nixos-generate-config`,
bare-metal install.
