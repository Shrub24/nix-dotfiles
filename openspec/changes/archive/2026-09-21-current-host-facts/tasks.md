# Tasks — Current-Host Facts Projection

## Group 1 — Registry and projection schema (3)

- [x] 1.1 Extend `topology.hosts.<name>` in `modules/policy/topology.nix` with a
  required `sshUser` field (`str`) and make `primaryUser` optional so
  build/admin machines can be registered without a repo-owned account.

  - refs: design D1, D6; spec current-host-facts "The fleet registry stays the single source of truth"
  - verify: `nix eval .#currentHostSchema 2>/dev/null` is not used — assert by
    evaluating each host output and confirming the registry entries type-check
    with and without `primaryUser`

- [x] 1.2 Delete the `remoteHosts` option from the registry schema and from the
  `arch` entry, replacing its three consumers with registry-derived views.

  - refs: design D6; spec ssh-client "Host aliases derive from the fleet registry"
  - criteria: no `remoteHosts` reference remains in `modules/` (`grep -rn remoteHosts modules`)

- [x] 1.3 Declare `currentHost` in `modules/policy/topology.nix` and publish it as
  `flake.modules.nixos.current-host`, `flake.modules.homeManager.current-host`,
  and `flake.modules.systemManager.current-host` with one shared schema
  (`id: str`, `primaryUser: { name; uid; gid; }`, `peers: attrsOf machine`).

  - refs: design D2, D3; spec current-host-facts "Each host evaluation receives a typed current-host record"
  - verify: `nix eval .#nixosConfigurations.shrub.config.currentHost.id` returns `"shrub"`

- [x] 1.4 Leave the registry declaration ownership explicit: each repository-owned
  machine contributes its own entry from its own host file, while the machines
  the repository does not own (`oci-melb-1`, `home-forge`, `la-admin-1`) and the
  `topology.services` endpoint map move out of `modules/hosts/arch.nix` into
  `modules/policy/topology.nix` as fleet-scoped declarations.

  - refs: design D1; spec current-host-facts "The fleet registry stays the single source of truth"
  - criteria: no host file declares a machine it does not configure

## Group 2 — Host composition wiring (2)

- [x] 2.1 Rename the registry key `arch` to `shrub` in `modules/hosts/arch.nix`
  and derive `currentHost` there from that entry, subtracting self from `peers`
  exactly once at the composition boundary.

  - refs: design D2, D3, D8; spec current-host-facts "The current-host record is projected at the composition boundary"
  - criteria: `lib.removeAttrs config.topology.hosts [ hostId ]` appears in the
    host file only; no feature module computes a peer set

- [x] 2.2 Add `flake.modules.*.current-host` and the `currentHost` value to all
  three module lists in `modules/hosts/arch.nix` (standalone HM, system-manager,
  NixOS + embedded HM).

  - refs: design D2; spec current-host-facts "Each host evaluation receives a typed current-host record"
  - verify: `nix flake check --no-build --no-write-lock-file`

## Group 3 — Reusable aspects read the projection (6)

- [x] 3.1 `modules/foundation/nixos.nix`: drop the flake-level `let` binding, read
  `config.currentHost.primaryUser` in the module body.

- [x] 3.2 `modules/desktop/greeter.nix`: read `config.currentHost.primaryUser` in
  both the systemManager and NixOS bodies.

- [x] 3.3 `modules/desktop/noctalia.nix`: read `config.currentHost.primaryUser`
  inside the `homeManager.noctalia` body for the greeter-sync UID.

- [x] 3.4 `modules/desktop-services.nix` and `modules/syncthing.nix`: read
  `config.currentHost.primaryUser` in the module body.

- [x] 3.5 `modules/nix.nix`: read `config.currentHost.primaryUser` and
  `pkgs.stdenv.hostPlatform.system` in the body; drop the topology `system` read.

- [x] 3.6 `modules/foundation/boot.nix`: it turned out no shared boot value
  needed the projection at all — the aspect now owns only host-agnostic behaviour
  (plymouth, btrfs scrub) and the Arch literals moved out (see 4.2). The
  `config` binding left the file entirely.

  - refs: design D1, D4; spec current-host-facts "Reusable features read the projection or native facts"
  - criteria: `grep -rn 'topology\.hosts\.' modules/` returns only the host
    composition file and fleet-aware consumers
  - verify: `nix flake check --no-build --no-write-lock-file`

## Group 4 — Native facts and relocated host literals (3)

- [x] 4.1 Delete `networking.hostName` and `system.stateVersion` from
  `modules/foundation/nixos.nix`; confirm `modules/hosts/arch/_nixos.nix`
  continues to declare both.

  - refs: design D4; spec dendritic-module-composition "Shared host and service data is typed and host-owned"
  - verify: `nix eval .#nixosConfigurations.shrub.config.networking.hostName`

- [x] 4.2 Move the Limine kernel command line and the dracut drop-in from
  `modules/foundation/boot.nix` into `modules/hosts/arch/_system.nix`, and the
  snapper configs into `modules/hosts/arch/_nixos.nix`.

  - refs: design D7; spec current-host-facts "Reusable features read the projection or native facts"
  - consequence: with every Arch-specific value relocated, there is no shared
    `systemManager.boot` aspect left to publish, so `boot` left `systemAspects`
    and `modules/foundation/boot.nix` now publishes `flake.modules.nixos.boot`
    alone (`systemAspects` was missing it and the eval caught that)
  - verify: the generated config was compared by evaluating the values that
    moved — `etc."default/limine".text` still carries
    `root=UUID=35eb40c3-6466-4e66-ad20-9b7da9140992`, the dracut drop-in still
    renders, and `services.snapper.configs` still defines root, home, and data

- [x] 4.3 Leave `foundation` owning only shared account and group creation driven
  by `currentHost.primaryUser`.

## Group 5 — Fleet-aware consumers (3)

- [x] 5.1 `modules/ssh.nix`: generate one `Host <name>` block per machine from the
  registry with that machine's `sshUser`; drop the blanket `User = "dev"` and the
  `remoteHosts` read.

- [x] 5.2 `modules/shell/wezterm.nix` and `modules/dev-tools/lazyjournal.nix`:
  consume the registry-derived peer list for mux domains and journal hosts.

- [x] 5.3 `modules/nix.nix`: derive the `home-forge` builder entry from
  `topology.hosts.home-forge` instead of inlining host, user, and architecture.

  - refs: design D5, D6; spec ssh-client "Host aliases derive from the fleet registry"
  - criteria: no machine hostname, login user, or architecture literal remains in
    a reusable aspect

## Group 6 — Validation (4)

- [x] 6.1 `nix flake check --no-build --no-write-lock-file` passes.

  - refs: spec repository-validation
  - verify: command exit status 0

- [x] 6.2 The two VM checks still boot (`vm-desktop`, `vm-skeleton-boot`).

  - verify: `vm-skeleton-boot` was built and run — it passes. `vm-desktop` fails
    at `home-manager-saurabhj.service`, and fails identically without this change:
    reverting the 14 touched files in a scratch copy
    (`cp -a . /tmp/nix-baseline` + `git checkout -- <files>`) and running the same
    check reproduces the same assertion. The run stops inside HM activation's
    `onFilesChange`, at the ghostty theme Noctalia renders at runtime — which a
    VM with no running shell never has. Owner ruling: a VM-only failure that is
    not indicative of real-system behaviour does not block this change.

- [x] 6.3 Confirm the Arch host's behaviour is unchanged: Home Manager activation
  closure, system-manager configuration, and NixOS toplevel all still evaluate;
  regenerated `/etc` content matches the pre-change generation except the
  intended ssh alias blocks.

  - refs: design "Goals"; spec current-host-facts
  - verify: `nix flake check --no-build --no-write-lock-file` exits 0 (all
    checks passed) plus per-value evals: `nixosConfigurations.shrub` still
    reports hostname `shrub` and stateVersion `26.11`, `nix.buildMachines` is
    byte-identical, the two `/etc/ssh/ssh_config.d` files list the same three
    hosts, and the Home Manager client config renders one `Host` block per peer
    with `User = dev` (the first attempt emitted `sshUser = dev`, which is not an
    ssh option — caught by this check)

- [x] 6.4 `nix fmt` clean; Statix and Deadnix pass over the touched files.

  - verify: `nix fmt -- --ci` and `nix flake check --no-build` lint checks

- [x] 6.5 `ARCHITECTURE.md` records the projection so the durable document still
  describes the composition model: the composition section names `currentHost`
  and the registry, and the topology decision states that declaration belongs to
  the registry and projection to the composition.

  - refs: design D2
