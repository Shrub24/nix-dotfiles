# Design — Bare-Metal NixOS Readiness

## Context

The NixOS output — today `nixosConfigurations.arch`, renamed to
`nixosConfigurations.shrub` by this change (D12) — is an evaluable skeleton, not a
switchable
host: it carries no Home Manager composition and only a smoke-test foundation
aspect. Bare-metal NixOS requires the NixOS target to embed the full Home
Manager composition and carry the hardware and identity enablement that keeps
the live Arch host behavior — before any install-day work. This change is the
prerequisite for `nixos-dual-boot-install`, which owns partition editing,
formatting, key copying, boot cleanup, and installation.

The repository already establishes the composition invariants this change
inherits: no `specialArgs`/`extraSpecialArgs` argument bus; typed `topology`
values declared once at the host composition layer; features own their
implementation details end to end. The `vm-desktop` check already embeds Home
Manager through `home-manager.nixosModules.home-manager` with
`useGlobalPkgs`/`useUserPackages`, so the NixOS-embedding shape is proven in
this repository.

## Goals / Non-Goals

**Goals:**

- Make the NixOS host (`nixosConfigurations.shrub`) switchable-ready: a full NixOS toplevel build
  transitively builds the embedded Home Manager configuration and every
  selected unfree and service package.
- Embed the complete Home Manager aspect set in NixOS target mode, filtering
  the aspects whose services or packages the NixOS target owns.
- Preserve the live host's identity (GID, locale, NVMe latency, zram-only) and
  service topology (Syncthing identity, Mosh, tailnet-scoped web ports,
  Snapper, Shared NTFS).
- Keep the standalone Arch Home Manager and system-manager configurations
  working until cutover.
- Validate with the existing VM checks and the full toplevel build; no new
  headless graphical-output assertion.

**Non-Goals:**

- Disk provisioning, UUID replacement, state copying, bootloader installation,
  and the actual installation — all owned by `nixos-dual-boot-install`.
- Changing Arch/system-manager runtime behavior; it remains as-is until
  retirement/cutover.
- Adding Surge — it remains unselected unless explicitly selected later.

## Decisions

### D1. Embed Home Manager in NixOS target mode

The NixOS host embeds Home Manager through the native NixOS module — the same
mechanism the `vm-desktop` check already exercises — instead of a second,
independently-evaluated `homeManagerConfiguration`:

```nix
nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
  modules = [
    (import ./arch/_nixos.nix { inherit primaryUser; })
    { nixpkgs.overlays = [ overlay ]; }
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${primaryUser.name} = {
          imports = [
            ./arch/_home.nix
            { targets.genericLinux.enable = false; }
          ] ++ map hmAspect embeddedHmAspects; # full set minus system-owned duplicates (D3)
        };
      };
    }
  ] ++ map nixosAspect nixosAspects;
  specialArgs = { };   # NO inputs/hostFacts bus — cleanup invariant
};
```

`embeddedHmAspects` is the existing `hmAspects` list with the system-owned
duplicates removed (D3). `useGlobalPkgs = true` + `useUserPackages = true`
mirror the VM check exactly, so the embedded HM shares the NixOS global pkgs
and profile. **No `specialArgs`/`extraSpecialArgs`** — the host raw file and
the lexical closure carry identity, preserving the cleanup invariant. The
standalone `homeConfiguration` keeps importing the same `_home.nix` and full
aspect list, with a small host-composition module setting
`targets.genericLinux.enable = true` and
`programs.niks3.enableAutoUploadService = true`. Its behavior and the
`systemConfiguration` remain unchanged until cutover.

### D2. Target discriminator: `targets.genericLinux`

`targets.genericLinux.enable` is the single target discriminator — HM's native
option. The host composition sets it explicitly: `true` beside `_home.nix` in
the standalone Arch module list and `false` beside `_home.nix` in the embedded
NixOS imports. `_home.nix` no longer sets it and no module tries to derive an
option from its own value. The Arch-only Niks3 enablement moves to the same
standalone composition module, so filtering the `niks3` aspect on NixOS cannot
leave an unknown option in `_home.nix`. The `system-manager` package and
Noctalia's pkexec branch on the normal `config.targets.genericLinux.enable`
value — no new option, no argument bus.

### D3. System-owned duplicate filtering

HM aspects that duplicate a NixOS-owned system service or package are omitted
from the embedded HM:

| HM aspect | NixOS owner | Why filtered |
|---|---|---|
| `tailscale` (package) | `services.tailscale` (CLI + daemon) | duplicate package |
| `syncthing` (user service) | `services.syncthing` system service | duplicate service |
| `mosh` (package) | native NixOS package (D9) | NixOS owns the package |
| `surge` (package) | `nixos.surge` aspect when selected | NixOS owns daemon + package; unselected now |
| `niks3` user uploader | `services.niks3-auto-upload` (D5) | user-runtime socket is pre-login-incompatible |

KDE Connect stays HM-owned: the `kde-apps` HM aspect keeps
`services.kdeconnect` (package + user daemon) and the NixOS `kde-apps` aspect
keeps firewall-only ownership (`programs.kdeconnect` with `package = null`) —
no change.

### D4. Unfree policy is host-owned

One predicate, defined lexically in `modules/hosts/arch.nix` as the union of
today's two predicates (host-local `_nixos.nix` + feature-owned HM `nix`):

```nix
unfreePredicate = pkg:
  (lib.hasPrefix "nvidia" (lib.getName pkg))
  || builtins.elem (lib.getName pkg) [
    "zsh-abbr" "byterover-cli" "vscode" "code" "unrar" "cuda_nvml_dev"
  ];
```

It is applied to the standalone HM pkgs and to the NixOS global pkgs. The
feature-owned `nixpkgs.config.allowUnfreePredicate` in the HM `nix` aspect is
**removed**, and `_nixos.nix` no longer sets its own predicate. With one
predicate shared by both scopes, `useGlobalPkgs` is valid (HM pkgs == NixOS
pkgs, identical `nixpkgs.config`). The final predicate also admits the exact
unfree packages in the CUDA toolkit closure; the toplevel build verifies that
allowlist rather than replacing it with `allowUnfree = true`. The `pkgsUnfree`
VM-only set is reused for the VM tests unchanged.

### D5. Native Niks3 auto-upload

The NixOS `nix` aspect currently sets `nix.settings."post-build-hook"` to a
user-runtime-socket hook (`/run/user/1000/niks3-upload-to-cache.sock`) — invalid
before login. That setting is dropped from the NixOS aspect.

`modules/niks3.nix` already publishes `flake.modules.nixos.niks3` using the
upstream `services.niks3-auto-upload` module; it is added to `nixosAspects`.
The feature module declares its root-owned token itself. The service consumes
the sops secret path directly; a second rendered template would add no value:

```nix
services.niks3-auto-upload = {
  enable = true;
  serverUrl = niks3ServerUrl;
  authTokenFile = config.sops.secrets.NIKS3_AUTH_TOKEN.path;
};
# same feature file:
sops.secrets.NIKS3_AUTH_TOKEN = { ... }; # root-owned, system scope
```

The token decrypts to a root-owned path and is referenced via `authTokenFile` —
never written to the store or a user path, never exposed. Arch behavior (HM
user uploader + user-socket hook) remains until cutover.

### D6. HM incompatibilities

- `_home.nix` `home.packages` drops `system-manager` when not generic Linux
  (`lib.mkIf config.targets.genericLinux.enable`).
- `programs.niks3.enableAutoUploadService` is not set on NixOS (user uploader
  omitted; the HM niks3 aspect becomes inert).
- Noctalia: `noctaliaGreeterSyncPkexec` resolves `/usr/bin/pkexec` only when
  `config.targets.genericLinux.enable`; on NixOS it resolves
  `/run/wrappers/bin/pkexec`. The pkexec wrapper is **not** enabled by default,
  so the NixOS target explicitly sets
  `security.polkit.enablePkexecWrapper = true`; the polkit rule for the wrapper
  installs via `environment.etc`. `systemd`/polkit behavior is otherwise
  unchanged.
- `DOTNET_ROOT = "/usr/bin"` is removed universally — it is invalid on NixOS
  and unused on Arch.

### D7. Hardware and host identity (NixOS scope)

`_hardware.nix` (host-local raw file, not an aspect) keeps host hardware:

- `hardware.enableRedistributableFirmware = true`
- `hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable`
  with `hardware.nvidia.open = true`. The live Arch host is running the open
  610.57 kernel module, and the user explicitly selected the stable NixOS
  package plus open module. This supersedes `_hardware.nix`'s stale
  "open module lacks reclocking" comment; the `nvidia` prefix is already
  allowed by the host predicate.
- `hardware.i2c.enable = true`
- `boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ]`
- zram only: keep `zramSwap`; no swap partition/file, no hibernation/resume
  device.

Ownership stays at the established boundaries:

- `topology.hosts.arch.primaryUser.gid = 1000` is declared once in
  `modules/hosts/arch.nix`; `modules/foundation/nixos.nix` creates the private
  primary group and assigns it to the account.
- `_nixos.nix` owns `i18n.defaultLocale = "en_AU.UTF-8"` as host identity.
- The existing system-services aspect owns `services.fwupd.enable = true`.

The existing `/mnt/Shared` NTFS and `/mnt/LinuxData` btrfs mounts, zram, and
microcode settings stay; only `nofail` (D9) and the enablements above change.

### D8. CUDA toolkit and libcamera are NixOS-target user tools

`hardware.cuda.enable` and `hardware.libcamera.enable` are not NixOS options in
the pinned/current NixOS. CUDA toolkit and libcamera are user CLI/tool
packages and become their own HM aspects — `flake.modules.homeManager.cuda`
(`modules/dev-tools/cuda.nix`) and `flake.modules.homeManager.libcamera`
(`modules/dev-tools/libcamera.nix`) — instead of entries in the shared `cli`
aspect. Activation is host-driven aspect selection: both are selected only in
the NixOS embedded HM composition (`embeddedHmAspects` in
`modules/hosts/arch.nix`) and never in the standalone generic-Linux
`hmAspects`. No in-module target gating. They are covered by the host-owned
unfree predicate (D4). No NixOS hardware option is invented.

### D9. Services: Syncthing, Mosh, tailnet scope, Snapper, NTFS

- **Syncthing identity:** `services.syncthing.configDir` is derived from the
  native `users.users.${primaryUser.name}.home` value, then extended with
  `.local/state/syncthing` — never a literal `~` (not expanded in NixOS service
  settings), a duplicated home path, or a hardcoded username.
  `overrideDevices = false` / `overrideFolders = false` stay, so config and
  device identity survive the cutover (no re-pairing).
  `openDefaultPorts = false` — the Syncthing listener ports (TCP/UDP 22000,
  UDP 21027) join the tailnet-scoped rules instead of a global opening.
- **Mosh:** `programs.mosh.enable = true` provides Mosh natively while
  `programs.mosh.openFirewall = false` suppresses the module's default global
  UDP opening; `networking.firewall.interfaces.tailscale0` alone allows
  60000–61000.
- **Tailnet scope:** LiteLLM TCP 8765 and web-catalog TCP 8123 are allowed on
  `tailscale0` only, so tailnet hosts reach them while nothing is exposed
  globally.
- **Snapper:** `services.snapper.configs` covers root, home, and data.
- **NTFS:** the `/mnt/Shared` mount gains `nofail` so a missing Windows
  partition never blocks boot; its `uid` and `gid` options derive from
  `primaryUser` rather than Arch-era numeric literals.

### D10. UWSM compositor registration

On NixOS, `programs.uwsm.waylandCompositors.niri` registers niri as the
compositor. This native registration replaces the custom launcher/desktop-file
tmpfiles the NixOS branch would otherwise need to start the niri session; niri
itself invokes `uwsm finalize` as part of its UWSM integration. The Arch
system-manager branch (uwsm from pacman) remains unchanged until retirement.

### D11. Validation

- `flake.checks.nixos-system` binds the toplevel; a **full build** (not
  `--no-build`) transitively builds the embedded HM activation and every
  selected unfree and service package — the switchable-readiness gate.
- `vm-desktop` waits for the greeter before sending login input and asserts the
  embedded Home Manager activation succeeds, so a store-invalid user config is
  not hidden behind a successful compositor launch. **No new headless
  graphical-output assertion** is added; graphics acceptance remains manual in
  the interactive `vm-desktop` check.

### D12. NixOS host identity: `shrub`

The NixOS host is a distinct host identity on the same machine —
`nixosConfigurations.shrub` with `networking.hostName = "shrub"` in
`_nixos.nix`, `foundation/nixos.nix`, and the VM fixtures — not a rename of the
Arch host. The typed topology entry stays keyed `topology.hosts.arch` until
cutover: it is machine-level data (primary user, remote hosts, service
endpoints) shared by all three outputs, and renaming the key alongside Arch
retirement (install change) avoids Arch-era outputs temporarily reading a
shrub-keyed entry. `system-manager` and NixOS are mutually exclusive targets,
so parallel per-target aspect implementations are expected; the embedded-HM
filter (D3) exists only to prevent same-host duplicate daemons, not to
deduplicate the repo.

## Risks / Trade-offs

- \[`useGlobalPkgs` requires identical `nixpkgs.config` between HM and NixOS; a
  feature-owned `allowUnfreePredicate` makes the embedded HM assert/fail\] →
  one host-owned predicate applied to both scopes; the HM `nix` aspect's
  predicate is removed.
- [Duplicate HM/system services if the filter misses an aspect] → the embedded
  HM is the full list minus the enumerated system-owned set (tailscale,
  syncthing, mosh, surge, niks3); review the resulting diff before switch.
- \[Native Niks3 auto-upload fails at runtime if the root-owned sops token is
  not provisioned\] → the feature module declares the secret so it is always
  present; eval gates cannot verify decryption, so confirm the root-owned sops
  `authTokenFile` exists on first boot.
- [CUDA toolkit adds significant store weight to the toplevel closure] →
  acceptable for a desktop host; revisit if closure size/build time matters.
- \[The stable NixOS open NVIDIA module behaves differently from the live Arch
  610.57 open module\] → validate PRIME offload, power management, external
  outputs, and sustained clocks before cutover; change driver branch/module
  only through an artifact amendment and explicit approval if that check fails.
- \[Syncthing identity lost if `configDir` diverges from the live HM state
  path\] → point `configDir` at the topology-derived absolute path and keep
  `overrideDevices`/`overrideFolders` false.
- [VM checks do not exercise real sops secrets, GPU, or firmware] → boot
  acceptance stays manual; the VM gates cover module-system conflicts, not
  hardware.

## Migration Plan

1. Add the host-owned unfree predicate in `modules/hosts/arch.nix` and remove
   the feature-owned predicate in the HM `nix` aspect; add
   `cudatoolkit`/`libcamera` to the HM CLI aspect.
1. Rework `arch.nix`/`_nixos.nix` to embed Home Manager via
   `home-manager.nixosModules.home-manager` with `useGlobalPkgs`/
   `useUserPackages` and the filtered aspect list.
1. Add the hardware/identity enablement to `_hardware.nix` (firmware, stable
   NVIDIA + open module, I2C, fwupd, group/locale/kernel/zram), the Shared NTFS
   `nofail` option, and the Snapper/Mosh/tailnet firewall on the NixOS side.
1. Drop the user-socket post-build hook from the NixOS `nix` aspect; add the
   `niks3` NixOS aspect with its root-owned sops token; set the Syncthing
   `configDir`.
1. Make the HM incompatibilities target-conditional (system-manager package,
   niks3 uploader, Noctalia pkexec with
   `security.polkit.enablePkexecWrapper = true`, DOTNET_ROOT removal); register
   niri via `programs.uwsm.waylandCompositors.niri`.
1. Gate on a full `nix flake check` (`nixos-system` toplevel) plus the
   unchanged VM checks.
1. At cutover, retire the standalone Arch HM/system-manager configs through the
   install change (`nixos-dual-boot-install`), not here.
