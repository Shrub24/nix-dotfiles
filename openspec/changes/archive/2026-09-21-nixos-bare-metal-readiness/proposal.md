## Why

`nixosConfigurations.arch` is today an evaluable skeleton, not a switchable
host. Bare-metal NixOS requires the NixOS target to embed the full Home
Manager composition and carry the hardware and identity enablement that keeps
the live Arch host behavior — before any install-day work. This readiness
change is a prerequisite for `nixos-dual-boot-install`, which owns partition
editing, formatting, key copying, boot cleanup, and installation.

## What Changes

- Rename the NixOS host identity to `shrub` (`nixosConfigurations.shrub`,
  `networking.hostName`); the `topology.hosts.arch` key is machine-level data and renames
  at cutover, not here.
- Make the NixOS host embed the complete Home Manager composition
  in NixOS target mode: `targets.genericLinux = false`; omit the
  `system-manager` package; omit the Arch user Niks3 uploader; filter
  system-owned duplicate HM aspects (`tailscale`, `syncthing`, `mosh`,
  `surge` as appropriate); use global pkgs/user packages; keep `topology` as
  the SSOT.
- Move/merge the unfree policy to host ownership so the embedded Home Manager
  works with `useGlobalPkgs`.
- Remove NixOS-incompatible literals: `/usr/bin/pkexec` becomes the NixOS
  wrapper in NixOS mode; drop the invalid `DOTNET_ROOT=/usr/bin`.
- Enable hardware and firmware: redistributable firmware, the Intel
  SOF/Wi-Fi firmware path, the stable open NVIDIA driver, I2C, fwupd, the
  CUDA toolkit and libcamera in NixOS target mode.
- Preserve live host identity and behavior: `primaryUser` gid 1000,
  `en_AU.UTF-8` locale, `nvme_core.default_ps_max_latency_us=0`, zram-only,
  no hibernation.
- Use native system Niks3 auto-upload with a root-owned sops token (the
  user-runtime post-build hook is pre-login-incompatible); maintain Arch
  behavior until cutover.
- Preserve Syncthing identity via its live Home Manager config directory; add
  the native Mosh firewall/module; expose LiteLLM 8765 and web-catalog 8123
  only on the tailnet;
  enable root/home/data Snapper; restore the Noctalia pkexec wrapper; use
  native UWSM compositor registration; Shared NTFS `nofail`.
- Docker daemon remains omitted (Podman owns containers); Ollama and Surge are
  intentionally omitted; no global exposure is invented.
- Validation: full bare-metal NixOS toplevel plus embedded Home Manager
  evaluation/build and the existing scoped VM checks, without adding fragile
  graphical-output assertions.

## Capabilities

### New Capabilities

- `nixos-bare-metal-readiness`: The NixOS host (`shrub`) is bare-metal-ready — the
  full Home Manager composition embedded in NixOS target mode, with
  hardware/firmware enablement, host-owned unfree policy, and preserved live
  host identity.

### Modified Capabilities

- `dendritic-module-composition`: NixOS host composition embeds the complete
  Home Manager aspect set in NixOS target mode, filters system-owned
  duplicates, and applies global pkgs/unfree host ownership while preserving
  the topology SSOT.
- `daemon-nix-config`: Native system Niks3 auto-upload with a root-owned sops
  token replaces the user-runtime post-build hook; daemon-level Nix policy
  moves to NixOS system scope.
- `secrets-ownership-model`: Niks3's upload credential becomes a root-owned
  service-scoped sops secret owned by the Niks3 feature module.
- `noctalia-shell`: The pkexec wrapper is restored through the NixOS wrapper
  and polkit rule in NixOS mode.
- `niri-home-manager`: The niri session is registered via native UWSM
  compositor registration.

## Impact

- `nixosConfigurations.shrub` host composition (`modules/hosts/arch.nix`,
  `_nixos.nix`) and the embedded Home Manager aspect set.
- Home Manager aspects that assume Arch-only paths (`/usr/bin/pkexec`,
  `DOTNET_ROOT=/usr/bin`) or duplicate system-owned services.
- Niks3, Syncthing, Mosh, Surge, Noctalia, and niri feature modules.
- No partition, formatting, key, boot, or install work — those belong to the
  dependent change `nixos-dual-boot-install`.
