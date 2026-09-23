# Architecture

This repository is a single-user Nix configuration for two hosts: an Arch desktop
(`legion`) and a portable NixOS laptop (`spectre`, HP Spectre x360
13-aw0039TU).
It composes three privilege-scoped layers from feature modules that are
discovered by directory scan but activated only by explicit host selection:
a user-scoped Home Manager configuration, a root-scoped system-manager
configuration (transitional, for the non-NixOS host), and a NixOS
configuration for the bare-metal hosts (`nixosConfigurations.legion` on the
desktop, `nixosConfigurations.spectre` on the laptop; the aspect side-port has
landed, the desktop's bare-metal install remains follow-up work).

`README.md` covers setup and operator commands. This document records the
durable boundaries, the composition model, and the design rationale.
Behavioral contracts live in the canonical specs under `openspec/specs/` and
are referenced here rather than restated.

## Overview / Boundaries

The split is along a privilege boundary, not a feature boundary:

- **User scope** — Home Manager (`homeConfigurations.saurabhj`) owns
  user-level programs, services, and secrets. Canonical contract:
  [system-manager-foundation](openspec/specs/system-manager-foundation/spec.md).
- **System scope (transitional)** — system-manager (`systemConfigs.legion`)
  owns daemons, root-owned state, and machine-wide configuration on the
  non-NixOS host. Same canonical contract, mirrored: daemon and root-owned
  concerns never live in Home Manager modules. Each system-manager aspect
  has a native NixOS counterpart activated on the NixOS target (side-port
  landed via `openspec/changes/nixos-boilerplate/`).
- **NixOS target** — `nixosConfigurations.legion` evaluates under
  `nix flake check` as a third host output, composing native NixOS aspects
  plus the full Home Manager composition embedded via
  `home-manager.nixosModules.home-manager` (`useGlobalPkgs`/`useUserPackages`
  over `embeddedHmAspects` — the HM aspect set minus the system-owned
  tailscale/syncthing/mosh/niks3 aspects, plus the NixOS-only
  cuda/libcamera aspects; `specialArgs` stays empty).
  Hardware configuration follows the `nixos-generate-config` convention at
  `modules/hosts/legion/_hardware.nix`: redistributable firmware, i2c,
  fwupd (desktop-services aspect), stable + open NVIDIA with Prime offload,
  `nvme_core.default_ps_max_latency_us=0`, the `en_AU.UTF-8` locale, snapper
  configs over the btrfs volumes, and the Windows-shared NTFS volume
  mounted `nofail` at `/mnt/Shared`.

Feature modules live in a single `modules/` tree — the only discovery
root. `import-tree` scans it; every unmarked `.nix` there is a flake-parts
module that publishes named aspects under `flake.modules.homeManager.<name>`,
`flake.modules.systemManager.<name>`, or `flake.modules.nixos.<name>`. Raw
class-specific modules are never scanned: they live only under `_`-named
segments (`/_` in a path is ignored). A feature spanning classes holds
multiple values in one file — `nix.nix`, `ssh.nix`, and `tailscale.nix`
each publish a homeManager, systemManager, and nixos aspect. Registration
is filesystem-driven; activation is host-driven.

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
  ├─ editors/nvim/       nvim.nix publishes the aspect; _*.nix raw modules
  ├─ apps/*.nix           end-user GUI apps (media, zathura, pavucontrol)
  ├─ apps/browser/*.nix   firefox, chromium, thunderbird, brave-origin — lazy HM enable
  ├─ desktop/*.nix        compositor + shell env (niri, noctalia, monique, vicinae, portals, greeter)
  ├─ foundation/*.nix    network → systemManager aspect; boot + nixos.nix (base-OS aspects)
  ├─ policy/*.nix        fleet contract + typed topology schema, endpoints, currentHost
  ├─ shell/*.nix         per-shell homeManager aspects + terminals (wezterm, ghostty, tmux)
  ├─ security/*.nix      sops-foundation + shared credentials aspects
  ├─ *.nix               nixbuild (systemManager), niks3/mosh/mutagen/syncthing
  │                      (homeManager); all but mutagen also publish a nixos aspect
  ├─ nix.nix ssh.nix tailscale.nix   homeManager AND systemManager AND nixos
  ├─ hosts/legion.nix      selects explicit aspect lists → host outputs (HM, system, NixOS)
  ├─ hosts/spectre.nix   selects the lean NixOS laptop set → nixosConfigurations.spectre
  ├─ hosts/legion/_*.nix   raw host files (_home, _system, _nixos, _hardware) — ignored
  └─ hosts/spectre/_*.nix  raw host files (_home, _nixos, _hardware) — ignored

Host composition lives in modules/hosts/legion.nix and modules/hosts/spectre.nix,
not flake.nix:
  ├─ 59 homeManager aspects + _home.nix    → homeConfigurations.saurabhj
  ├─ 7 systemManager aspects + _system.nix → systemConfigs.legion
  └─ 19 nixos aspects + _nixos.nix + embedded HM → nixosConfigurations.legion

modules/hosts/spectre.nix composes the laptop as a NixOS-only host —
no standalone HM output and no system-manager counterpart (the embedded
Home Manager is its only configuration path):
  └─ 37 lean HM aspects (phase-gated) + _home.nix, 15 nixos aspects +
     _nixos.nix + _hardware.nix + embedded HM → nixosConfigurations.spectre

Build dispatch is resolved, not restated. `nix-fleet` owns the canonical
inventory — target system, tailnet hostname, SSH host key — and this repository
declares only its own scheduling policy over it: a build profile naming
`home-forge`, and the dispatch account that builder currently authorizes. The
host composition resolves that policy into normalized specs and hands them to
the contract's pure projectors, which render `nix.buildMachines` on NixOS and
`/etc/nix/machines` on the non-NixOS host, where system-manager has no such
option. Nothing about the builder is hand-written, so the two renderers cannot
disagree about who gets dialed. Membership is the whole policy: a build hook
ranks only the configured machines against each other, so a scheduled builder
accepts everything and no weight or predicate expresses "prefer local".
```

The fleet registry and the service endpoint map are typed options
(`topology.hosts.<id>`, `topology.services.<name>.host`) declared in
`modules/policy/topology.nix` — their declaration sits beside the schema because
they describe machines and endpoints, not one host: a machine this repository
configures contributes its own registry entry from its own host file, and the
machines it only reaches are declared with the schema. Consumers read them via
the normal module system — there is no `specialArgs`/`extraSpecialArgs` argument
bus and no ambient facts record.

Machine identity is not ours to own. `modules/policy/fleet.nix` imports
`nix-fleet`'s contract, so target system, tailnet hostname and SSH host key come
from the canonical inventory rather than from a second copy here, and
`topology.hosts` keeps only what this repository decides: the login user and the
account it configures. A machine's identity has one author.

A reusable feature never reads a registry key, because that would make one aspect
value serve only the machine whose key it names. Each host composition projects
its own entry into `currentHost` (`id`, `primaryUser`, `peers`), under the
`current-host` aspect published for all three classes, so an aspect reads
`config.currentHost.primaryUser` or `config.currentHost.peers.<name>.sshUser` and
is identical in every evaluation. The projection is computed from the registry at
the composition boundary — the only place that knows which entry is "self" — and
nothing is injected into the class evaluations. Native facts are read where a
native option exists: hostname and state version are declared by the host's own
NixOS module, and a package's architecture comes from
`pkgs.stdenv.hostPlatform.system` rather than the topology.

Package recipes and the local overlay are owned by `pkgs/default.nix`; feature
modules reference published packages rather than defining derivations inline.

### Inputs and the fleet federation

This repository is one of three: `nix-fleet` (the shared platform aspects and
implementation), `nix-homelab` (the servers) and this one (the workstations).
`flake.nix` is generated by `flake-file` from input declarations in the module
tree — the flake entry point is plumbing, and inputs are owned where they are
used: a feature declares its own input in its own file, the flake plumbing and
the package layer declare theirs in `modules/flake/inputs.nix`. The generated
file carries a do-not-edit header, `modules/flake/` imports flake-file's core
module rather than its dendritic preset, and nested `follows` sit beside the
input they redirect rather than behind flake-file's auto-follow module. That
module rewrites follows through flake-edit and discards whatever a module
declares, which would leave the generated file holding state the tree cannot
reproduce. With declared follows, `checks.check-flake-file` is a real derivation
check: it fails whenever the checked-in file and the declarations disagree.

Dependency authority is explicit. `nix-fleet` owns the pins both repositories
share — `nixpkgs`, `flake-parts`, `import-tree`, `treefmt-nix` — and this flake
consumes them as _follows_ onto `nix-fleet/<input>` rather than carrying its own
URLs, so a single nix-fleet update moves them together instead of letting two
copies drift. Everything else — home-manager, system-manager, Noctalia, desktop
and agent tooling — is this repository's own input, updating independently and
converging on the inherited nixpkgs. `sops-nix` and `niks3` stay repository-owned
deliberately: nix-fleet declares its copies for fixture evaluation only, not as
an authority other repositories follow.

Tooling is reused where nix-fleet already owns it: `modules/flake/tooling.nix`
imports `nix-fleet.flakeModules.tooling` for the shared treefmt definition (the
same formatters and the pinned priorities that make them converge) and adds only
this repository's exclusions and operator surface. Policy and UX composition stay
here; `nix-fleet` contributes mechanism.

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
[daemon-nix-config](openspec/specs/daemon-nix-config/spec.md). The NixOS
target adds one more root secret: the `niks3` NixOS aspect decrypts
`NIKS3_AUTH_TOKEN` as a root-owned sops secret and feeds the rendered path
straight to the root-scoped `services.niks3-auto-upload` — no
user-runtime-socket hook on NixOS, and the embedded Home Manager drops the
niks3 uploader aspect (`embeddedHmAspects`).

**User scope.** All other secrets are user-scoped sops, owned in three
places: a SOPS foundation aspect (`modules/security/sops.nix`, module import +
age key + tooling), a shared credentials aspect
(`modules/security/credentials.nix`, the cross-feature provider and tool keys in
one encrypted file per consumer group — `llm-providers.yaml`, `web-search.yaml`,
`github.yaml`, `sourcegraph.yaml`), and each service's own feature module (its
service-specific secrets and rendered env templates — `aichat.env`,
`grist.env`, `docs-mcp.env`, `hermes.env`, `niks3-auth-token`,
`nix-access-tokens`). A consumer that can resolve a key itself reads the
decrypted secret path — pi providers and pi-web-access via `!cat`, MCP headers
via `!command` — and only keys whose consumer can read nothing but the
environment reach the shared `agent-env.env` template. Secrets decrypt once by
the merged sops config and templates render into the Home Manager generation,
so ownership is relocated without changing the rendered outputs. No user secret
is exposed to the root daemon, and no system secret is rendered into user
state. Canonical contract:
[secrets-ownership-model](openspec/specs/secrets-ownership-model/spec.md).

## Service Lifecycle

User services follow systemd's own lifecycle model instead of activation
orchestration. Docs MCP and Grist declare `X-Restart-Triggers` on their
generated config and decrypted secret paths, so a config or secret change
restarts the service declaratively. Activation hooks remain only where the
service manager cannot model the work.

Active user services: docs-mcp, grist, qmd, web-catalog, moniqued, memex's
hourly index timer, surge (the
headless download daemon on port 1700), niks3-auto-upload (a socket-activated
cache upload queue), and the weekly nh-clean timer — which is a user timer only on the non-NixOS host: on
NixOS the fleet's `nh-gc` capability owns that unit and runs `nh clean all` as
root, which covers user generations too, so GC has exactly one owner per host
scope. Podman storage is pruned weekly through the platform's own
`virtualisation.podman.autoPrune` rather than nix-fleet's `podman-prune` aspect:
nixpkgs defines the `podman-prune` unit unconditionally, so the two cannot
coexist. Systemd failure notifications come from the fleet's `notify`
capability, dispatched to ntfy — services opt in by writing
`services.notify.events.<unit>.failure` from the module that owns the unit, or
from the host module for units only that host runs; package-provided units
(`nix-daemon`, `tailscaled`) register with `fromPackage`. Machine metrics go to
the fleet's `beszel-agent` capability (hub on the la-admin-1 host of
nix-homelab), enrolled behind the same two-step sops gate as the other
system-scoped secrets: the fleet-wide agent key in `secrets/beszel.yaml`, the
per-host enrollment token in `secrets/hosts/<id>/beszel.yaml`. The contributor
aspects inject host policy — secret paths and tailnet exposure — while the
fleet aspect owns the unit, its template, and its notify registration.
LLM traffic goes to the OmniRoute gateway on the builder host, an endpoint the
fleet topology carries (`topology.services.omniroute.host`).
Service ports and display metadata are owned by `lib/web-services.nix`
(grist 8484, docs-mcp 6280, qmd 8181, web-catalog 8123);
canonical contract: [web-service-catalog](openspec/specs/web-service-catalog/spec.md).
Grist binds loopback only (`127.0.0.1:8484`) and is not reverse-proxied;
its bundled SQLite state persists at `~/.local/share/grist`.
On NixOS, exposure is tailnet-scoped: the global firewall stays closed, and
Mosh (UDP 60000–61000), web-catalog 8123, and Syncthing's
relay/discovery ports are allowed on `tailscale0` only — Syncthing sets
`openDefaultPorts = false` so its ports follow the same rules.
The laptop (`spectre`) selects no local service tier: its clients reach the
desktop's and the forge's services over the tailnet, so the service list above
describes only machines that are always on.

## Durable Decisions

- **Monique is the sole monitor authority** — niri's store-linked config
  includes Monique-owned runtime state and HM defines no inline output
  blocks, so hotplug handling is never split between config layers.
- **Niri config is store-linked** — the compositor boots from a read-only
  store path, making the desktop session fully declarative.
- **Noctalia GUI state is runtime state** — the shell owns its mutable
  settings outside the store; treat them as machine-local, not declarative
  configuration.
- **Noctalia themes through its own template entries, declared locally** —
  `theme.templates.enable_builtin_templates` and `enable_community_templates`
  are off, and every entry is a row in `modules/desktop/noctalia.nix`. A row
  names a store path input (the noctalia package for builtins, the pinned
  `community-templates` flake input for the rest), an output path, and a hook
  only where Nix cannot point the consuming application at the rendered file.
  The inverse — enabling upstream template ids and bending the Nix config around
  their hooks — was rejected: hooks that rewrite store-linked configs fail, and
  a Nix-owned file cannot be a template's output.
- **Discovery is scoped to the single `modules/` tree** — `import-tree` scans
  only `modules/`; raw class modules live at `_`-prefixed paths, which
  `import-tree` ignores, so dormant files cannot alter a host accidentally.
- **Machine identity is canonical, policy is local** — nix-fleet's contract owns
  what a machine _is_ (target system, tailnet hostname, SSH host key); this
  repository owns what it _does_ (the login user, the account it configures,
  which builders it schedules). Service endpoints are typed options declared in
  `modules/policy/topology.nix`, and each host composition projects its own entry
  into `currentHost` for the class evaluations it builds. Features read the
  projection or the native option, never a registry key and never a hardcoded
  hostname, so one aspect value is correct for every host and nothing travels
  through an argument bus.
- **Trust is its own door** — which machines this one talks to is a separate
  selection from which may build for it, resolved through the contract's
  `resolveHosts` rather than a build profile. Trust never implies use and use
  never implies trust, so naming a host for one cannot silently grant the other.
  Host keys land in the system known-hosts file rather than the user's, because
  ssh appends to the latter.
- **System secrets stay out of user scope** — owned end to end by
  system-manager on Arch and by the sops-nix OS module on NixOS; a root
  credential is never rendered through user-scoped Home Manager state.
- **One durable document** — `ARCHITECTURE.md` records boundaries and
  rationale; the filesystem inventory duplicate was deleted because it
  diverged from implementation.
- **A file an application rewrites is never Nix-owned** — the Herdr and Pi
  configuration surfaces are rendered by the `programs.herdr` and
  `programs.pi-coding-agent` Home Manager modules, but the test is the write
  path, not whether the file holds settings. Pi's `settings.json` is declared
  because its failed write is a caught `EACCES` that reports loudly; the three
  extension settings files — `pi-tool.json`, `pi-stamp.json`, and
  `pi-herdr.json` — are not, because they save through a
  temporary file plus `rename()`, which replaces a store symlink with a real
  file instead of failing, and diverges silently.
- **Pi agent definitions live under the Pi agent directory** — the seven
  subagent definitions are repository files mounted at `~/.pi/agent/agents`.
  `~/.agents` is the cross-tool agent directory that `opencode.nix` also
  symlinks, so Pi-specific personas are not placed there. Extension paths in a
  definition are written relative to the definition file, which keeps them free
  of hardcoded home directories.

## Verification

One canonical validation command runs locally, pre-push, and in CI:

```sh
nix flake check --no-build --no-write-lock-file
```

`nix fmt` (treefmt-nix) is both formatter and formatting check — nixfmt for
Nix, and prettier for Markdown, YAML and JSON. Flake checks cover Statix and Deadnix over all
maintained Nix source (nvfetcher's `pkgs/_sources` is excluded at the
source-set level, not via suppressions), the treefmt check, and full
evaluation of the Home Manager activation package, the system-manager
configuration, the NixOS toplevel, and the NixOS VM test derivations — a
change that breaks any host output fails CI without switching anything.
Lefthook runs fast formatting and lint checks at pre-commit and the canonical
no-build check at pre-push; GitHub Actions runs the same check on pull
requests with pinned action revisions.
