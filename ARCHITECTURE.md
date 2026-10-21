# Architecture

This repository is a single-user Nix configuration for two laptops: `legion`
(Lenovo Legion Slim 7 16IRH8) and a portable `spectre` (HP Spectre x360 13-aw0039TU). Both
are NixOS — `nixosConfigurations.legion` and `nixosConfigurations.spectre`.
Each composes feature modules that are discovered by directory scan but
activated only by explicit host selection, and each embeds the user-scoped
Home Manager configuration beside its system-scoped NixOS aspects.

`README.md` covers setup and operator commands. This document records the
durable boundaries, the composition model, and the design rationale.
Behavioral contracts live in the canonical specs under `openspec/specs/` and
are referenced here rather than restated.

## Overview / Boundaries

The split is along a privilege boundary, not a feature boundary:

- **User scope** — the embedded Home Manager configuration owns user-level
  programs, services, and secrets. There is no standalone HM output: Home
  Manager runs only as an embedded NixOS configuration.
- **System scope** — the NixOS aspect set owns daemons, root-owned state, and
  machine-wide configuration. Daemon and root-owned concerns never live in
  Home Manager modules.
- **NixOS hosts** — `nixosConfigurations.legion` and
  `nixosConfigurations.spectre` evaluate under `nix flake check`, composing
  native NixOS aspects plus the full Home Manager composition embedded via
  `home-manager.nixosModules.home-manager` (`useGlobalPkgs`/`useUserPackages`
  over each host's HM aspect list; `specialArgs` stays empty). Legion's HM
  aspect list includes cuda/libcamera/codex; tailscale/syncthing/mosh/niks3
  appear only in its NixOS list.
  Both hosts derive detected drivers, redistributable firmware and microcode
  from committed nixos-facter reports. Their `_hardware.nix` files keep
  explicit host policy. Legion's includes i2c, stable + open NVIDIA with
  Prime offload, `nvme_core.default_ps_max_latency_us=0` and the shared NTFS
  volume mounted `nofail` at `/mnt/Shared`. Snapper lives in its `_nixos.nix`;
  fwupd and locale are shared aspects.

Feature modules live in a single `modules/` tree — the only discovery
root. `import-tree` scans it; every unmarked `.nix` there is a flake-parts
module that publishes named aspects under `flake.modules.homeManager.<name>` or
`flake.modules.nixos.<name>`. Raw
class-specific modules are never scanned: they live only under `_`-named
segments (`/_` in a path is ignored). A feature spanning classes holds
multiple values in one file — `nix.nix`, `ssh.nix`, and `tailscale.nix`
each publish a homeManager and nixos aspect. Registration
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
  ├─ foundation/*.nix    boot, network, nixos (base-OS aspects)
  ├─ policy/*.nix        fleet contract + typed topology schema, endpoints, currentHost
  ├─ shell/*.nix         per-shell homeManager aspects + terminals (wezterm, ghostty, tmux)
  ├─ security/*.nix      sops-foundation + shared credentials aspects
  ├─ *.nix               nixbuild (nixos), niks3/mosh/mutagen/syncthing
  │                      (homeManager); all but mutagen also publish a nixos aspect
  ├─ nix.nix ssh.nix tailscale.nix   homeManager AND nixos
  ├─ hosts/legion.nix      selects explicit aspect lists → nixosConfigurations.legion
  ├─ hosts/spectre.nix   selects the lean NixOS laptop set → nixosConfigurations.spectre
  ├─ hosts/legion/ssh-identities.nix  HM/NixOS identities
  ├─ hosts/legion/_*.nix   raw host files (_home, _nixos, _hardware, _disko, _storage) — ignored
  └─ hosts/spectre/_*.nix  raw host files (_home, _nixos, _hardware, _disko) — ignored

Host composition lives in modules/hosts/legion.nix and modules/hosts/spectre.nix,
not flake.nix:
  └─ nixos aspects + _nixos.nix + _disko.nix + embedded HM → nixosConfigurations.legion

modules/hosts/spectre.nix composes the laptop with the same shape and a leaner
aspect set:
  └─ nixos aspects + _nixos.nix + _hardware.nix + _disko.nix + embedded HM
     → nixosConfigurations.spectre

Legion's embedded Home Manager includes the NixOS-only cuda, libcamera and codex
aspects; tailscale, syncthing, mosh and niks3 are system-owned and appear only as
NixOS aspects.

The Legion counts above include `legion-ssh-identities` in each class: it delivers client keys through Home Manager and the
builder and server host keys through the NixOS layer, from
`secrets/hosts/legion/ssh.yaml`.
[Identity enrollment](docs/runbooks/enroll-legion-identities.md) records the
one-time import and external age-key bootstrap required for a fresh install.

Build dispatch is resolved, not restated. `nix-fleet` owns the canonical
inventory — target system, tailnet hostname, SSH host key — and this repository
declares only its own scheduling policy over it: a build profile naming
`home-forge`, and the dispatch account that builder currently authorizes. The
host composition resolves that policy into normalized specs and hands them to
the contract's pure projector, which renders native `nix.buildMachines` on the
NixOS host, so no separate machines file or hand-written
builder definition is needed. Membership is the whole policy: a build hook
ranks only the configured machines against each other, so a scheduled builder
accepts everything and no weight or predicate expresses "prefer local". Slot
budget is the offload knob instead — the hook takes any scheduled builder with
a free slot and falls back to the local machine only when none has one, which
makes a workstation's own concurrency an overflow budget. `home-forge` is asked
for eight jobs, while local builds are capped at four jobs with four cores each
and the daemon runs under `batch` CPU and `idle` I/O scheduling with a CPU
weight and `MemoryHigh` bound, so a build cannot saturate an interactive
session.
```

The fleet registry is a typed option (`topology.hosts.<id>`) declared in
`modules/policy/topology.nix` — its declaration sits beside the schema because it
describes machines, not one host: a machine this repository configures
contributes its own registry entry from its own host file, and the machines it
only reaches are declared with the schema. Consumers read it through the normal
module system — there is no `specialArgs`/`extraSpecialArgs` argument bus and no
ambient facts record. Service endpoints are not declared here: consumers resolve
them from nix-fleet's canonical service inventory
(`lib.serviceEndpoints.url config.fleet { … }`), which is the same shaping —
typed, declared once, read through the module system — with the declaration
owned by the contract that validates it.

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
copies drift. Everything else — home-manager, Noctalia, desktop
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
(`generateKey = false`, so a missing key cannot silently become a new identity).
`nix-daemon` orders after and wants
`sops-install-secrets.service`, and rotation restarts it declaratively via
`restartUnits`. Canonical contract:
[daemon-nix-config](openspec/specs/daemon-nix-config/spec.md). The `niks3` NixOS
aspect adds one more root secret: it decrypts
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
`grist.env`, `hermes.env`, `niks3-auth-token`,
`nix-access-tokens`). A consumer that can resolve a key itself reads the
decrypted secret path — pi providers and pi-web-access via `!cat`, MCP headers
via `!command` — and only keys whose consumer can read nothing but the
environment reach the shared env templates — one key list rendered per shell
dialect (`agent-env.env` for POSIX shells, `agent-env.fish` for fish), so each
shell sources its own syntax directly. Secrets decrypt once by the merged sops
config and templates render into the Home Manager generation,
so ownership is relocated without changing the rendered outputs. No user secret
is exposed to the root daemon, and no system secret is rendered into user
state. Canonical contract:
[secrets-ownership-model](openspec/specs/secrets-ownership-model/spec.md).

Git configuration is Home Manager-owned through the `git` aspect: Git LFS,
delta, user preferences, GitHub CLI settings and its credential helper are
native module declarations. Interactive GitHub authentication remains in the
login keyring; neither the OAuth token nor the keyring is a Nix-owned file.
Legion's enrollment-gated SSH identity aspect delivers private keys from a
host-specific encrypted file, so restoring those keys requires the bootstrap
age identities, not a surviving home directory. Age identities stay externally
provisioned: encrypting the bootstrap key with itself would make recovery circular.

## Service Lifecycle

User services follow systemd's own lifecycle model instead of activation
orchestration. Docs MCP and Grist declare `X-Restart-Triggers` on their
generated config and decrypted secret paths, so a config or secret change
restarts the service declaratively. Activation hooks remain only where the
service manager cannot model the work.

Active user services: grist, qmd, mcp-nixos, web-catalog, moniqued, memex's
hourly index timer, surge (the
headless download daemon on port 1700), and niks3-auto-upload (a socket-activated
cache upload queue). Garbage collection has no user-scoped timer: the fleet's
`nix-gc` capability owns the units — hourly unconditional collection, daily
root pruning through `nh clean all --no-gc`, and a weekly optimise pass this
repo switches off because btrfs dedups as paths are written. All run as root,
which covers user generations too, so GC has exactly one owner.
Podman storage is pruned weekly through the platform's own
`virtualisation.podman.autoPrune` rather than nix-fleet's `podman-prune` aspect:
nixpkgs defines the `podman-prune` unit unconditionally, so the two cannot
coexist. Systemd failure notifications come from the fleet's `notify`
capability, dispatched to ntfy — services opt in by writing
`services.notify.events.<unit>.failure` from the module that owns the unit, or
from the host module for units only that host runs; package-provided units
(`nix-daemon`, `tailscaled`) register with `fromPackage`. MCP servers reach Pi
the same way: the aspect that owns one writes its
`programs.pi-coding-agent.mcpServers` entry
and the pi aspect renders the register as store-managed `mcp.json` files for
the default agent and each Pi-Bolt role, so the only servers Pi names itself are
the endpoints this repository does not serve
(grep.app, sourcegraph, and the fleet's docs-mcp). Machine metrics go to
the fleet's `beszel-agent` capability (hub on the la-admin-1 host of
nix-homelab). The agent holds no secret: the key it verifies the hub with is the
hub's own _public_ half, so it is policy data bound by the contributor rather
than a sops secret, and there is no enrollment gate. The contributor aspects
inject host policy — the hub key and tailnet exposure — while the fleet aspect
owns the unit and its notify registration.
Prometheus-lane host metrics go through the fleet's `telemetry` and
`node-exporter` aspects: the node exporter binds loopback on 9100 and vmagent
forwards it to the one declared `fleet-metrics` destination, resolved from the
fleet inventory (`lib.serviceEndpoints`, `victoriametrics/remote-write` over the
tailnet) in `modules/telemetry.nix` and pinned by
`services.telemetry.pipelines.metrics`. vmagent's own loopback health scrape
(8429) rides that same pipeline — which is also the blind spot, since a total
transport outage hides its own health samples, leaving silence detection to the
backend. Pi's `pi-otel` fork exports through the local OTLP collector
(`127.0.0.1:4318`): traces reach the fleet's canonical home-forge gateway, which
owns Langfuse/Latitude fanout and credentials, while metrics reach the metrics
store — the only pipeline that carries them. Both workstations admit traces and
metrics locally and keep logs off. Full capture includes prompts, completions
and tool I/O. The extension compiles into the Pi-Bolt executable; the pinned runtime
package with its npm dependencies remains available to stock Pi. Journal shipping stays off
(`adopt-fleet-journals`), and Beszel keeps its dashboard lane alongside.
LLM traffic goes to the OmniRoute gateway on the builder host, an endpoint the
fleet service inventory carries (`lib.serviceEndpoints`).
Service ports and display metadata are owned by `lib/web-services.nix`
(grist 8484, qmd 8181, mcp-nixos 8000, web-catalog 8123, pi-dashboard 8100);
canonical contract: [web-service-catalog](openspec/specs/web-service-catalog/spec.md).
Grist binds loopback only (`127.0.0.1:8484`) and is not reverse-proxied;
its bundled SQLite state persists at `~/.local/share/grist`.
On NixOS, exposure is tailnet-scoped: the global firewall stays closed, and
Mosh (UDP 60000–61000), web-catalog 8123 on legion, and
Syncthing's relay/discovery ports are allowed on `tailscale0` only — Syncthing sets
`openDefaultPorts = false` so its ports follow the same rules.
The laptop (`spectre`) selects no local service tier: its clients reach
legion's and the forge's services over the tailnet, so the service list above
describes only machines that are always on.

## Decisions

Decisions, their rejected alternatives and their revisit triggers live in
`context/` (see `context/index.md`).

## Verification

One canonical validation command runs locally, pre-push, and in CI:

```sh
nix flake check --no-build --no-write-lock-file
```

`nix fmt` (treefmt-nix) is both formatter and formatting check — nixfmt for
Nix, and prettier for Markdown, YAML and JSON. Statix and Deadnix are devShell tools run by lefthook, not flake
checks. Flake checks evaluate the treefmt check and both NixOS toplevels and
VM test derivations, so a change that breaks any host output fails CI without
switching anything.

The fleet build (`.github/workflows/fleet-build.yml`, dispatch-only) is the only
workflow that builds and publishes. It builds `.#ciRoot`: the non-VM outputs
for x86_64-linux. Decision and revisit triggers are in
`context/ci-fleet-build.md`.
Lefthook runs fast formatting and lint checks at pre-commit and the canonical
no-build check at pre-push; GitHub Actions runs the same check on pull
requests with pinned action revisions.
