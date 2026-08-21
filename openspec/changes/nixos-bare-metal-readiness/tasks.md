# Tasks — NixOS Bare-Metal Readiness

## Group 1 — Composition and identity (6)

- [x] 1.1 Add `primaryUser.gid = 1000` to the topology declaration in
  `modules/hosts/arch.nix`; make `modules/foundation/nixos.nix` create
  `users.groups.${primaryUser.name}` from that value and assign it as the account's primary
  group (matches Arch user-private-groups).

  - refs: design D7; spec nixos-bare-metal-readiness "Live host identity is preserved"
  - verify: nix eval .#nixosConfigurations.shrub.config.users.groups.${primaryUser.name}.gid == 1000

- [x] 1.2 Remove the leftover `targets.genericLinux = { enable = true; gpu.enable = true; }`
  block from `_home.nix`: the standalone side already sets `enable` in `arch.nix`, and
  `gpu.enable` defaults to `genericLinux.enable && nixGL.packages == null`, so deletion is
  safe for both evals. This resolves the verified embedded-eval plain-definition conflict.

  - refs: design D2; spec dendritic-module-composition "Target mode is discriminated by targets.genericLinux"
  - criteria: both evals produce the correct `targets.genericLinux.enable` value with no conflict error

- [x] 1.3 Define one lexical host-owned unfree predicate in `modules/hosts/arch.nix`
  (union of today's host-local + feature-owned predicates) and apply it to both the
  standalone HM pkgs and the NixOS global pkgs.

  - refs: design D4; spec dendritic-module-composition "Unfree policy is host-owned"

- [x] 1.4 Remove the feature-owned `nixpkgs.config.allowUnfreePredicate` from the HM
  `nix` aspect so `useGlobalPkgs` is valid.

  - criteria: no feature module declares its own `nixpkgs.config.allowUnfreePredicate`

- [x] 1.5 Embed the full HM aspect set in NixOS target mode via
  `home-manager.nixosModules.home-manager` with `useGlobalPkgs`/`useUserPackages`,
  imports containing `_home.nix`, the explicit NixOS target module, and
  `embeddedHmAspects` = `hmAspects` minus the system-owned set (`tailscale`, `syncthing`,
  `mosh`, `surge`, `niks3`), with `specialArgs = {}` and no `extraSpecialArgs`.

  - criteria: the embedded user retains every `_home.nix` setting while the filtered `niks3` option is absent and does not cause an unknown-option error

  - refs: design D1, D3; spec dendritic-module-composition "NixOS hosts embed Home Manager natively" + "NixOS host embeds the Home Manager aspect set"

- [x] 1.6 Rename the NixOS host identity to `shrub`: `flake.nixosConfigurations.shrub` in
  `arch.nix`; `networking.hostName = "shrub"` in `_nixos.nix`, `foundation/nixos.nix`, and
  both VM fixtures. The `topology.hosts.arch` key is machine-level data shared by all
  outputs and renames at cutover (install change), not here.

  - refs: design D12
  - criteria: `nixosConfigurations.shrub` evaluates; no Arch-era output (`systemConfigs.arch`, `homeConfigurations.saurabhj`) is renamed

## Group 2 — Home Manager target compatibility (4)

The niks3 user uploader needs no conditional here — the embedded HM filters the whole
`niks3` aspect (1.5), so there is no NixOS user uploader to condition; the standalone
Arch aspect stays unchanged.

- [x] 2.1 Drop the `system-manager` package from `_home.nix` `home.packages` when not
  generic Linux (`lib.mkIf config.targets.genericLinux.enable`).

  - refs: design D6

- [x] 2.2 Remove `DOTNET_ROOT = "/usr/bin"` universally (invalid on NixOS, unused on
  Arch).

  - refs: design D6

- [x] 2.3 Make Noctalia's pkexec path target-conditional: `/usr/bin/pkexec` on generic
  Linux, `/run/wrappers/bin/pkexec` on NixOS; set `security.polkit.enablePkexecWrapper = true` and install the polkit rule via `environment.etc` on the NixOS target.

  - refs: design D6; spec noctalia-shell "NixOS target resolves the wrapper"
  - criteria: NixOS eval resolves `/run/wrappers/bin/pkexec`; Arch eval resolves `/usr/bin/pkexec`

- [x] 2.4 Register niri via `programs.uwsm.waylandCompositors.niri` on NixOS, replacing
  only the NixOS custom launcher/desktop-file tmpfiles; leave the Arch system-manager
  UWSM branch unchanged. (Implemented in the greeter NixOS aspect, which owns session
  registration.)

  - refs: design D10; spec niri-home-manager "niri session is registered through native UWSM"

## Group 3 — Native Niks3 (5)

- [x] 3.1 Drop the user-runtime-socket post-build hook from the NixOS `nix` aspect
  only (`nix.settings."post-build-hook"`); keep the Arch system-manager hook plus the
  HM uploader (the hook is not HM-owned).

  - refs: design D5; spec daemon-nix-config "No user-runtime post-build hook on NixOS"

- [x] 3.2 Declare the root-owned `NIKS3_AUTH_TOKEN` sops secret in
  `modules/niks3.nix` at system scope; consume its decrypted path directly and never expose
  it in the repo, the Nix store, or user scope.

  - refs: design D5; spec secrets-ownership-model "A system-scoped service secret is root-owned"

- [x] 3.3 Complete and activate the existing `niks3` NixOS aspect: replace the hardcoded
  `authTokenFile = "/run/secrets-rendered/niks3-auth-token"` literal with the evaluated
  `config.sops.secrets.NIKS3_AUTH_TOKEN.path`, and add `niks3` to `nixosAspects` in
  `arch.nix`.

  - refs: design D5; spec daemon-nix-config "Native system Niks3 auto-upload is the NixOS post-build path"
  - criteria: authTokenFile = `config.sops.secrets.NIKS3_AUTH_TOKEN.path` (evaluated), never a hardcoded runtime-path literal

- [x] 3.4 Update sops recipients/key config so the new secret decrypts on the NixOS host —
  no secret values in the diff.

  - verify: decrypted authTokenFile path resolves at eval; no secret material in the change

- [x] 3.5 Retain the Arch branch (HM user uploader + user-socket hook) unchanged until
  cutover.

  - criteria: standalone Arch HM/system-manager evaluation unchanged

## Group 4 — Hardware and tooling (4)

- [x] 4.1 Complete hardware and firmware enablement: in `_hardware.nix` set
  `hardware.nvidia.open = true` (stable package already set) and replace the stale
  reclocking comment with the approved live-open/stable-package decision, plus
  `hardware.enableRedistributableFirmware = true` and `hardware.i2c.enable = true`;
  enable `services.fwupd.enable = true` in the system-services owner
  (`modules/desktop-services.nix`, not `_hardware.nix`).

  - refs: design D7; spec nixos-bare-metal-readiness "Hardware and firmware are enabled"

- [x] 4.2 Add the remaining identity to NixOS scope: `i18n.defaultLocale = "en_AU.UTF-8"`
  in `_nixos.nix` and `boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ]` in
  `_hardware.nix` (zram-only is already in place; no swap file/partition or
  hibernation/resume).

  - criteria: locale stays in `_nixos.nix`; kernel and zram settings stay in `_hardware.nix`
  - refs: design D7; spec nixos-bare-metal-readiness "Live host identity is preserved"

- [x] 4.3 Add `cudaPackages.cudatoolkit` and `libcamera` as their own HM
  aspects (`modules/dev-tools/cuda.nix` → `flake.modules.homeManager.cuda`,
  `modules/dev-tools/libcamera.nix` → `flake.modules.homeManager.libcamera`),
  removing them from the `cli` aspect; select both only in the NixOS embedded
  HM aspect set (`embeddedHmAspects` in `modules/hosts/arch.nix`), never in the
  standalone Arch `hmAspects`.

  - refs: design D8; spec nixos-bare-metal-readiness "Hardware and firmware are enabled"
  - criteria: the NixOS embedded HM package set contains both tools; the standalone
    generic-Linux HM package set contains neither

- [x] 4.4 Extend the host-owned unfree predicate to exactly cover the unfree packages in
  the CUDA toolkit closure; verified by the full toplevel build — do not use
  `allowUnfree = true`.

  - refs: design D4, D8
  - verify: full toplevel build succeeds with the allowlist

## Group 5 — Services and storage (5)

- [x] 5.1 Point NixOS Syncthing at the live HM state: set `configDir` (and `dataDir`) from
  the native `users.users.${primaryUser.name}.home` value extended with
  `/.local/state/syncthing`; set `openDefaultPorts = false` so the listener ports
  (TCP/UDP 22000, UDP 21027) join the tailnet-scoped rules; keep
  `overrideDevices`/`overrideFolders` false (already set).

  - refs: design D9; spec nixos-bare-metal-readiness "Syncthing identity is preserved"
  - criteria: the live Arch directory exists and contains the current Syncthing identity before the NixOS service is switched to it
  - verify: inspect the live path without exposing key contents, then eval the topology-derived NixOS path

- [x] 5.2 Enable native Mosh with `programs.mosh.enable = true` and
  `programs.mosh.openFirewall = false`; allow UDP 60000–61000 on `tailscale0` only.

  - refs: design D9; spec nixos-bare-metal-readiness "Mosh is reachable over the tailnet only"
  - criteria: mosh module enabled; automatic global firewall opening false; UDP range only under `networking.firewall.interfaces.tailscale0`

- [x] 5.3 Open LiteLLM TCP 8765 and web-catalog TCP 8123 on `tailscale0` only; no global
  exposure; Surge remains unselected.

  - refs: design D9; spec nixos-bare-metal-readiness "User web services are reachable only on the tailnet" + "Surge stays unselected"

- [x] 5.4 Configure Snapper for the root, home, and data btrfs volumes
  (`services.snapper.configs`).

  - refs: design D9; spec nixos-bare-metal-readiness "Snapshots cover the btrfs volumes"

- [x] 5.5 Add `nofail` to the `/mnt/Shared` NTFS mount so a missing Windows partition
  never blocks boot; derive its `uid` and `gid` mount options from `primaryUser`.

  - refs: design D9; spec nixos-bare-metal-readiness "Shared NTFS is non-fatal"
  - criteria: `/mnt/Shared` uses `nofail`, `primaryUser.uid`, and `primaryUser.gid`

## Group 6 — Verification and docs (5)

- [x] 6.1 Scoped evals first: `nix eval .#nixosConfigurations.shrub.config.system.build.toplevel.drvPath` and the standalone
  Arch HM/system-manager configs still evaluate.

  - verify: toplevel drvPath eval + standalone configs eval both succeed

- [x] 6.2 Full NixOS toplevel build (not `--no-build`) transitively building the embedded
  HM activation, the CUDA closure, and every selected service/unfree package.

  - refs: design D11; spec nixos-bare-metal-readiness "The NixOS toplevel is fully buildable"

- [x] 6.3a Repair the Ghostty `config-file` reference exposed by embedded Home Manager
  activation. The generated Ghostty configuration SHALL not resolve a runtime-only relative
  include from the Nix store; do not hide the fault by disabling Ghostty in VM fixtures.

  - criteria: `home-manager-saurabhj.service` activation no longer fails on the Ghostty include;
    `vm-desktop` asserts that activation; standalone HM behavior remains valid; the repair stays
    feature-local

- [x] 6.3 Run the existing `vm-desktop` and `vm-skeleton-boot` checks; permit only minimal
  fixture adjustments required by the new composition. Import the Niks3 aspect so its
  options and secret declaration evaluate, but force `services.niks3-auto-upload.enable = false` in VM fixtures because no real auth token is provisioned there.

  - refs: design D11; spec nixos-bare-metal-readiness "Validation uses the existing scoped checks"
  - criteria: checks pass; `home-manager-saurabhj.service` has no Ghostty activation failure;
    no dummy secret value; no byte-unchanged requirement on fixtures; no new headless graphical-output assertion

- [x] 6.4 Delegate ARCHITECTURE/README command and boundary updates to DocWriter, only
  where host composition behavior actually changed.

  - delegate: DocWriter

- [x] 6.5 Final gate: `nix flake check --no-build --no-write-lock-file`, formatting check
  (treefmt), and `openspec validate --all --strict`.

  - verify: all three commands green
