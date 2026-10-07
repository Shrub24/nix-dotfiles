# Architecture

This repository is a single-user Nix configuration for two hosts: a desktop
(`legion`) and a portable laptop (`spectre`, HP Spectre x360 13-aw0039TU). Both
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
  over each host's HM aspect list; `specialArgs` stays empty). Legion's
  `embeddedHmAspects` is its HM aspect set minus the system-owned
  tailscale/syncthing/mosh/niks3 aspects, plus the NixOS-only
  cuda/libcamera/codex aspects.
  Hardware configuration follows the `nixos-generate-config` convention at
  `modules/hosts/legion/_hardware.nix`: redistributable firmware, i2c,
  fwupd (desktop-services aspect), stable + open NVIDIA with Prime offload,
  `nvme_core.default_ps_max_latency_us=0`, the `en_AU.UTF-8` locale, snapper
  configs over the btrfs volumes, and the Windows-shared NTFS volume
  mounted `nofail` at `/mnt/Shared`.

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
  ├─ hosts/legion/ssh-identities.nix  enrollment-gated HM/NixOS identities
  ├─ hosts/legion/_*.nix   raw host files (_home, _nixos, _hardware, _disko, _storage) — ignored
  └─ hosts/spectre/_*.nix  raw host files (_home, _nixos, _hardware, _disko) — ignored

Host composition lives in modules/hosts/legion.nix and modules/hosts/spectre.nix,
not flake.nix:
  └─ 24 nixos aspects + _nixos.nix + _disko.nix + embedded HM → nixosConfigurations.legion

modules/hosts/spectre.nix composes the laptop with the same shape and a leaner
aspect set:
  └─ 20 nixos aspects + _nixos.nix + _hardware.nix + _disko.nix + embedded HM
     → nixosConfigurations.spectre

The embedded Home Manager on legion composes 63 aspects (`embeddedHmAspects`:
64 selected HM aspects minus the system-owned tailscale/syncthing/mosh/niks3,
plus the NixOS-only cuda/libcamera/codex). Spectre's embedded Home Manager
composes 45 lean aspects (phase-gated alongside its NixOS set).

The Legion counts above include one enrollment-gated aspect in each class,
selected by `sshIdentitiesEnrolled`:
`legion-ssh-identities` delivers client keys through Home Manager and the
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
environment reach the shared `agent-env.env` template. Secrets decrypt once by
the merged sops config and templates render into the Home Manager generation,
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
`nh-gc` capability owns the unit and runs `nh clean all` as
root, which covers user generations too, so GC has exactly one owner.
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
and the pi aspect renders the register into `~/.pi/agent/mcp.json`, so the only
servers Pi names itself are the endpoints this repository does not serve
(grep.app, sourcegraph, and the fleet's docs-mcp). Machine metrics go to
the fleet's `beszel-agent` capability (hub on the la-admin-1 host of
nix-homelab). The agent holds no secret: the key it verifies the hub with is the
hub's own _public_ half, so it is policy data bound by the contributor rather
than a sops secret, and there is no enrollment gate. The contributor aspects
inject host policy — the hub key and tailnet exposure — while the fleet aspect
owns the unit and its notify registration.
LLM traffic goes to the OmniRoute gateway on the builder host, an endpoint the
fleet service inventory carries (`lib.serviceEndpoints`).
Service ports and display metadata are owned by `lib/web-services.nix`
(grist 8484, qmd 8181, mcp-nixos 8000, web-catalog 8123);
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
- **System secrets stay out of user scope** — owned end to end by the sops-nix
  OS module; a root credential is never rendered through user-scoped Home
  Manager state.
- **One durable document** — `ARCHITECTURE.md` records boundaries and
  rationale; the filesystem inventory duplicate was deleted because it
  diverged from implementation.
- **A file an application rewrites is never Nix-owned** — the Pi
  configuration surface is rendered by the `programs.pi-coding-agent` Home
  Manager module, but the test is the write path, not whether the file holds
  settings. Pi's `settings.json` is declared
  because its failed write is a caught `EACCES` that reports loudly; the
  extension settings files `pi-tool.json` and `pi-stamp.json` are not, because they save through a
  temporary file plus `rename()`, which replaces a store symlink with a real
  file instead of failing, and diverges silently.
- **Delegation is herdsman; pane state is Herdr's own integration** —
  `pi-herdsman` replaces `pi-subagents`, which is gone outright: no extension
  row, no `subagents` settings block and no rendered config remain. What that
  block carried lives where its owner reads it — the disabled roles through
  herdsman's own `disabledDefinitions`, a child's extensions and provider
  through its agent definition. The official `herdr integration install pi`
  replaces `@narumitw/pi-herdr`. The integration is a file Herdr writes to
  `~/.pi/agent/extensions/herdr-agent-state.ts`, so it stays imperative and is
  re-run after a Herdr upgrade. Herdsman passes a definition's `skills` paths
  to Pi unchanged, so the agent definitions carry `@home@` placeholders that the
  Home Manager module substitutes at build time, and the drift guard reads the
  skill names back out of those paths. A skill whose absence would break the
  role's core work is preloaded — its body inlined into every child request,
  at the cost of that skill's tokens — instead of only advertised, because an
  advertisement lets the model skip the read. That is `lean-implementation`
  for worker and delegate, `review-policy` and `lean-implementation` for
  reviewer, and `evidence-discipline` for researcher and evidence-auditor;
  every other skill stays advertised and is read when its work needs it. Two
  publishers of pane metadata never run at once: the swap is one change.

- **Herdsman's config is seeded, not linked** — `pi-herdsman/config.json` is
  rewritten atomically whenever settings change through `/agents`, so it takes
  the same treatment as Herdr's `config.toml`: an activation step merges the
  keys this repository owns — `disabledDefinitions` for the bundled
  generalist/implementer roles, and `modelScopes` for the per-role model
  allow-lists — into the real file, and everything set through the UI survives
  a switch. A scope only restricts, so each list names the models that
  definition actually pins.

- **Plugin-owned config tables are declared, not merged** — Herdr and its
  plugins rewrite `config.toml` by renaming a temporary file over the real
  path, so a store symlink breaks them with `EACCES` in `/nix/store`. The file
  is therefore rendered from `programs.herdr.settings` but written as a real
  file at activation, and the blocks herdr-radar owns are re-applied in the same
  step, so a switch re-seeds the published keys and the plugin reinstalls its
  own layout rather than leaving a stale copy behind.

  TOML allows a table once, which makes declaring one the way to keep it.
  `[theme.custom]` is declared so Herdr's theme name stays this repository's
  choice rather than the panel-fill value the plugin installs along with it; the
  plugin finds a foreign table and skips its theme block. Its sidebar panel is
  deliberately not declared: the plugin rebuilds that block per appearance and
  its daemon re-probes the desktop's, so a Nix-declared copy pins one appearance
  — and while the table is ours the plugin reads the panel as someone else's and
  disables its own ordering, which is how a declared panel quietly costs the
  activity sort.

- **Pi agent definitions live under the Pi agent directory** — the seven
  subagent definitions are repository files mounted at `~/.pi/agent/agents`.
  `~/.agents` is the cross-tool agent directory that `opencode.nix` also
  symlinks, so Pi-specific personas are not placed there. Extension paths in a
  definition are written relative to the definition file, which keeps them free
  of hardcoded home directories.
- **Pi-Bolt plugin sources are flake inputs** — its local extensions come from
  the `pi-extensions` input, advanced by `nix flake update pi-extensions` and
  replaceable for a local build with `--override-input`. `pkgs/pi-plugins` is
  the one place a compiled plugin's recipe lives: where its source comes from
  (an npm pin, a path in that input, or a pinned upstream checkout), which
  file exports its factory, and the patch its compile-time assumptions need,
  applied with `--replace-fail` so a moved upstream fails loudly. Every source
  here is a pin: the npm tarballs by hand, the local plugins from the
  `pi-extensions` input, and OmniRoute's `deploy/edge` checkout through
  nvfetcher like the rest of `pkgs/_sources` — so the running configuration
  never reads a live checkout, and `nix flake update pi-extensions` is what
  moves the local plugins' code. The launcher disables extension discovery, so
  compiled plugins need not be removed from the normal Pi `packages` list. Loop Police's mutable config lives in the agent directory;
  Ask User Question keeps its built-in English fallback in the compiled build.

  A compiled factory is unconditional: `--no-extensions` disables discovery and
  Pi's built-ins, not the factories baked into the binary, so which plugins are
  compiled is a build-time decision with two answers — `pkgs/pi-bolt` builds the
  recipes it is handed and carries no selection of its own. The lead build is
  the operator's session; the child build is what a delegated child launches
  with, which is why it leaves out the renderer, starship, vim and recap the
  operator wants and the child does not. Both are derived from one row table:
  a row's `compiled` list names the builds that contain it. Two plugins need
  help being compiled: Loop Police and Ask User Question read a file beside
  their own source, which no longer exists once the source is bytes in the
  binary, so their paths move to a Pi-provided location or their fallback; and
  permission-system resolves its bash-parser wasm through `require.resolve`,
  which is a build-time resolution and so becomes an embedded file import, after
  which the `npm root -g` walk is dead code worth short-circuiting.

  Compiled plugin code must also bind the modules the executable runs: Pi's own
  tsconfig points the host packages at `packages/*/src` while the build bundles
  `packages/*/dist`, so a plugin compiled from that map gets a second copy of the
  host's classes and a class-style patch — the renderer's user-message component —
  lands on a class the app never renders with. `pkgs/pi-bolt` stages a tsconfig
  beside the plugin files that moves the coding-agent entry to `dist`, and the AOT
  ceiling it exports is the largest single module's top-level bytecode, re-measured
  when the plugin set changes.

  What a binary does not contain must still reach the session, and that is the
  one place both Pi entry points read the same list: one row per extension in
  `modules/agents/_pi-extensions.nix` yields the settings `packages` entry the
  discovery-based `pi` loads and the extension path a discovery-denied Pi-Bolt
  launch passes. A row that loads without an installed path, or compiles without
  a recipe, fails evaluation rather than going quietly missing.

- **One extension list serves both Pi binaries** — the definitions' extension
  paths are written for upstream pi, and the child launcher drops the ones its
  own binary already compiles in rather than registering them twice. That drop
  is load-bearing rather than hygiene: on the CLI a duplicate is a startup
  failure, so a definition still naming a compiled plugin presents as a pane
  that never comes up. The launchers pass `--no-extensions` for the same reason
  — it suppresses the settings `packages` set, though not the compiled
  factories — and the child launcher supplies it with the two builtins a child
  needs when the launch does not, so a child started without herdsman's own flag
  list is still complete. The wrapper is the only place that can make that
  choice, and `pi` is that wrapper rather than a name a shell function shadows:
  installed with `lib.hiPrio` over the stock package's own `pi`, so a script or a
  bash shell reaches Pi-Bolt too, while the stock binary stays installed under its
  own name, `pi-stock`. Routing is not ours: the lead launcher exports
  `PI_HERDSMAN_CHILD_COMMAND`, and pi-herdsman — which creates the pane itself —
  runs that command as the child's process (`herdr pane run <pane> '<command>
--extension …'`), so no shell function or per-kind override is involved. Herdr's
  own `agent start --kind pi` path, which types the canonical `pi` into the pane's
  shell, is only the fallback for a lead that sets no command.
  Herdsman supplies its own session layout flags (`--session-dir`, `--session`)
  and nothing intercepts them, which is what keeps a child's sessions in
  `.pi/sessions/children`, while operator sessions stay in the global root
  (`~/.pi/agent/sessions`) — Pi resolves one session root at a time, so a
  project-local operator `sessionDir` hides every pre-existing session from the
  picker, `--continue`, Magic Context and Memex (removed 2026-10-06; migrating
  the operator's sessions into their projects stays a manual step).
  `pi-stock` is the stock binary, so degrading costs no rebuild.

- **The why lives in `context/`** — the keep-the-why skill owns it: decisions,
  rejected alternatives, workarounds, incidents and constraints, each with a
  status and a revisit trigger. `ARCHITECTURE.md` describes the current shape,
  `CONVENTIONS.md` holds the rules, OpenSpec holds intended behaviour, and
  `context/` holds why any of it is the way it is. Durable Decisions entries
  move there as the skill's retrospective pass reaches them.

- **Session mode is a launch choice** — plain `pi` is the implementor with the
  user in the loop; `pio` appends `~/.pi/agent/modes/orchestrator.md`. A mode is
  appended prompt text fixed for the session, so the prompt cache sees one head,
  and `AGENTS.md` stays mode-neutral.

- **A managed child cannot be given its own agent directory** — the obvious way
  to quiet a child's TUI is a second agent directory plus a fish `pi` wrapper
  that points `PI_CODING_AGENT_DIR` at it, with only `settings.json` differing.
  pi-herdsman refuses it: the child derives its mailbox path from the agent
  directory and compares that string with the `PI_HERDSMAN_MAILBOX` its parent
  passed, so a linked or renamed directory makes it classify itself as unmanaged
  and the launch dies with `pane_not_ready`. Normalising both sides through
  `realpath` upstream is the prerequisite; until then the thin definitions are
  the whole child-side TUI reduction.

- **Implementation discipline has one source** — the `lean-implementation`
  skill. Agent definitions that write or review code list it and tell the agent
  to read it; the global `AGENTS.md` points at it. `CONVENTIONS.md` only applies it to
  this repository's boundaries, and role definitions keep only role mechanics (escalation, report shape),
  so a change to the discipline is a one-file edit that every role picks up.

## Verification

One canonical validation command runs locally, pre-push, and in CI:

```sh
nix flake check --no-build --no-write-lock-file
```

`nix fmt` (treefmt-nix) is both formatter and formatting check — nixfmt for
Nix, and prettier for Markdown, YAML and JSON. Flake checks cover Statix and Deadnix over all
maintained Nix source (nvfetcher's `pkgs/_sources` is excluded at the
source-set level, not via suppressions), the treefmt check, and full
evaluation of both NixOS toplevels and the NixOS VM test derivations — a
change that breaks any host output fails CI without switching anything.
Lefthook runs fast formatting and lint checks at pre-commit and the canonical
no-build check at pre-push; GitHub Actions runs the same check on pull
requests with pinned action revisions.
