# Architecture

This repository is a single-user Nix configuration for one Arch desktop host.
It composes two privilege-scoped layers — a user-scoped Home Manager
configuration and a root-scoped system-manager configuration — from feature
modules that are discovered by directory scan but activated only by explicit
host selection.

`README.md` covers setup and operator commands. This document records the
durable boundaries, the composition model, and the design rationale.
Behavioral contracts live in the canonical specs under `openspec/specs/` and
are referenced here rather than restated.

## Overview / Boundaries

The split is along a privilege boundary, not a feature boundary:

- **User scope** — Home Manager (`homeConfigurations.saurabhj`) owns
  user-level programs, services, and secrets. Canonical contract:
  [system-manager-foundation](openspec/specs/system-manager-foundation/spec.md).
- **System scope** — system-manager (`systemConfigs.arch`) owns daemons,
  root-owned state, and machine-wide configuration on the non-NixOS host.
  Same canonical contract, mirrored: daemon and root-owned concerns never
  live in Home Manager modules.

Feature modules live in a single `modules/` tree — the only discovery
root. `import-tree` scans it; every unmarked `.nix` there is a flake-parts
module that publishes named aspects under `flake.modules.homeManager.<name>`
or `flake.modules.systemManager.<name>`. Raw class-specific modules are
never scanned: they live only under `_`-named segments (`/_` in a path is
ignored). A feature spanning both classes holds both values in one file —
`nix.nix`, `ssh.nix`, and `tailscale.nix` each publish a homeManager and a
systemManager aspect. Registration is filesystem-driven; activation is
host-driven.

## Composition

The flake is a minimal manifest: inputs, discovery, and host composition.
`flake.nix` declares the inputs, calls `flake-parts.lib.mkFlake`, imports
`(inputs.import-tree ./modules)`, and sets `systems` — no module logic lives
there. import-tree scans the single `modules/` root: every unmarked `.nix`
is a flake-parts module publishing named aspects; paths containing `/_` are
ignored.

```
modules/                 ← import-tree scan (the only discovery root)
  ├─ flake/*.nix         declares the flake.modules option; perSystem tooling
  ├─ agents/<feature>.nix  one file per feature → homeManager aspect
  ├─ agents/litellm/     default.nix publishes the aspect; _*.nix raw modules
  ├─ apps/*.nix           end-user GUI apps (media, zathura, pavucontrol)
  ├─ apps/browser/*.nix   firefox, chromium, thunderbird, brave — lazy HM enable
  ├─ desktop/*.nix        compositor + shell env (niri, noctalia, monique, vicinae, portals, greeter)
  ├─ foundation/*.nix    network, boot → systemManager aspects
  ├─ shell/*.nix         per-shell homeManager aspects + terminals (wezterm, ghostty, tmux)
  ├─ security/*.nix     sops-foundation + shared credentials aspects
  ├─ *.nix               nixbuild, niks3, mosh, mutagen, syncthing — single-aspect
  ├─ nix.nix ssh.nix tailscale.nix   both homeManager AND systemManager
  ├─ hosts/arch.nix      selects explicit aspect lists → host outputs
  └─ hosts/arch/_*.nix   raw host files (facts, home, system) — ignored

Host composition lives in modules/hosts/arch.nix, not flake.nix:
  ├─ ~40 homeManager aspects + _home.nix    → homeConfigurations.saurabhj
  └─ 7 systemManager aspects + _system.nix → systemConfigs.arch
```

Service and host topology and machine identity live once in the typed
`topology` option (`topology.hosts.<name>`, `topology.services.<name>.host`)
declared at the host composition layer in `modules/hosts/arch.nix`, plus
native Home Manager options (`home.username`, `home.homeDirectory`,
`pkgs.stdenv.hostPlatform.system`) for host identity. Feature modules read
these via the normal module system — there is no `specialArgs`/`extraSpecialArgs`
argument bus and no ambient facts record. Package recipes and the local
overlay are owned by `pkgs/default.nix`; feature modules reference published
packages rather than defining derivations inline.

## Secrets & Privilege

Secrets follow the same split as the configuration layers: each secret is
decrypted and rendered by whichever layer owns its consumer.

**System scope (root).** The Nixbuild credential is the one system secret.
`modules/nixbuild.nix` imports the sops-nix NixOS module, reads
`secrets/nixbuild.yaml`, and renders the token to
`/run/secrets/rendered/nixbuild.net.env` as root-owned `0400`. Decryption uses
a pre-generated root-owned age key at `/var/lib/sops-nix/key.txt`
(`generateKey = false`; automatic generation is unsupported in
system-manager). `nix-daemon` orders after and wants
`sops-install-secrets.service`, and rotation restarts it declaratively via
`restartUnits`. Canonical contract:
[daemon-nix-config](openspec/specs/daemon-nix-config/spec.md).

**User scope.** All other secrets are user-scoped sops, owned in three
places: a SOPS foundation aspect (`modules/security/sops.nix`, module import +
age key + tooling), a shared credentials aspect
(`modules/security/credentials/agents.nix`, the ~20 cross-feature LLM/provider
API keys from `secrets/agents.yaml` plus the shell-wide `zsh-secrets.env`),
and each service's own feature module (its service-specific secrets and
rendered env templates — `litellm.env`, `aichat.env`, `grist.env`,
`docs-mcp.env`, `hermes.env`, `niks3-auth-token`, `nix-access-tokens`).
Secrets decrypt once by the merged sops config and templates render into the
Home Manager generation, so ownership is relocated without changing the
rendered outputs. No user secret is exposed to the root daemon, and no system
secret is rendered into user state. Canonical contract:
[secrets-ownership-model](openspec/specs/secrets-ownership-model/spec.md).

## Service Lifecycle

User services follow systemd's own lifecycle model instead of activation
orchestration. Docs MCP, LiteLLM, and Grist declare `X-Restart-Triggers`
on their generated config and decrypted secret paths, so a config or
secret change restarts the service declaratively. Activation hooks remain only where the
service manager cannot model the work.

The one retained Home Manager activation is the LiteLLM OCI image load
(`home.activation.litellmImageLoad`): the patched image is loaded into podman
once at activation rather than in `ExecStartPre`, avoiding the repeated
unpack/restart loop that exhausted disk. LiteLLM runs from an OCI image
because its Prisma client and migrations are impractical to package in Nix —
see Durable Decisions.

Active user services: docs-mcp, grist, litellm (with optional headroom
sidecar), qmd, web-catalog, moniqued, niks3-auto-upload (a socket-activated
cache upload queue), and the weekly nh-clean timer.
Service ports and display metadata are owned by `lib/web-services.nix`
(grist 8484, litellm 8765, docs-mcp 6280, qmd 8181, web-catalog 8123);
canonical contract: [web-service-catalog](openspec/specs/web-service-catalog/spec.md).
Grist binds loopback only (`127.0.0.1:8484`) and is not reverse-proxied;
its bundled SQLite state persists at `~/.local/share/grist`.
The LiteLLM gateway behavior is contracted by
[litellm-gateway](openspec/specs/litellm-gateway/spec.md).

## Durable Decisions

- **LiteLLM runs from a patched OCI image** — its Prisma client requires
  schema-specific pre-generation across npm, prisma-engines, and a Python
  build environment that breaks across versions; the upstream OCI image ships
  a working Prisma runtime.
- **Monique is the sole monitor authority** — niri's store-linked config
  includes Monique-owned runtime state and HM defines no inline output
  blocks, so hotplug handling is never split between config layers.
- **Niri config is store-linked** — the compositor boots from a read-only
  store path, making the desktop session fully declarative.
- **Noctalia GUI state is runtime state** — the shell owns its mutable
  settings outside the store; treat them as machine-local, not declarative
  configuration.
- **Discovery is scoped to the single `modules/` tree** — `import-tree` scans
  only `modules/`; raw class modules live at `_`-prefixed paths, which
  `import-tree` ignores, so dormant files cannot alter a host accidentally.
- **Hosts and services own their topology** — identity and service data live
  once in the typed `topology` option and native Home Manager options, declared
  at the host composition layer and read via the module system, never hardcoded
  in feature modules or passed through an argument bus.
- **System secrets are owned end to end by system-manager** — a root daemon
  credential is not rendered through user-scoped Home Manager state.
- **One durable document** — `ARCHITECTURE.md` records boundaries and
  rationale; the filesystem inventory duplicate was deleted because it
  diverged from implementation.

## Verification

One canonical validation command runs locally, pre-push, and in CI:

```sh
nix flake check --no-build --no-write-lock-file
```

`nix fmt` (treefmt-nix) is both formatter and formatting check — nixfmt for
Nix, mdformat for Markdown. Flake checks cover Statix and Deadnix over all
maintained Nix source (nvfetcher's `pkgs/_sources` is excluded at the
source-set level, not via suppressions), the treefmt check, and full
evaluation of the Home Manager activation package and the system-manager
configuration — a change that breaks either host output fails CI without
switching anything. Lefthook runs fast formatting and lint checks at
pre-commit and the canonical no-build check at pre-push; GitHub Actions runs
the same check on pull requests with pinned action revisions.
