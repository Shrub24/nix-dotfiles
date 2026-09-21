# Design — Current-Host Facts Projection

## Context

`topology.hosts.<name>` and `topology.services.<name>` are declared as
flake-parts options in `modules/policy/topology.nix` and populated in
`modules/hosts/arch.nix`. Because the flake-parts configuration is evaluated
once, any aspect that closes over `config.topology.hosts.arch` produces one
value for the whole flake: eleven reusable aspects are therefore single-host.

The dendritic pattern forbids the two obvious escapes. Per-host aspect clones
are the "lower-level module name proliferation" anti-pattern, and passing host
facts as function arguments or `specialArgs` is the argument-bus anti-pattern.
The remaining mechanism the module system provides is a typed option that each
host evaluation sets for itself.

This change performs that cleanup before a second host exists, so the second
host can select existing aspects unchanged. It is a prerequisite for
`add-spectre-host`.

## Goals / Non-Goals

**Goals:**

- Make every reusable aspect host-agnostic: no hardcoded topology key, no host
  literal, no self-identification logic.
- Keep one fleet registry as the single source of truth for machines, peer
  logins, and service endpoints.
- Give each host evaluation a typed record of the facts Nix does not already
  provide, projected through the normal module system.
- Keep the evaluated behaviour of the existing Arch host identical, proved by
  the existing checks and by comparing relocated generated files.
- Leave the repository ready for `add-spectre-host` with no further refactor.

**Non-Goals:**

- Adding the second host, its hardware, or its install plan.
- Re-keying flake outputs: `flake.systemConfigs.arch`,
  `flake.homeConfigurations.saurabhj`, and `flake.nixosConfigurations.shrub`
  keep their names. The desktop output rename belongs to
  `nixos-dual-boot-install`.
- Changing the secrets model, the privilege split, or any service endpoint.
- Introducing `specialArgs`, `extraSpecialArgs`, or a `host` argument bus.

## Decisions

### D1. The global registry stays, and stops being read by reusable features

`topology.hosts.<name>` and `topology.services.<name>` remain flake-parts
options declared in `modules/policy/topology.nix` and populated by every
flake-parts module that owns a fact worth registering. They are the fleet
registry: which machines exist, how to reach them, and which endpoints services
live at.

Declaration ownership follows the fact. A machine this repository configures
contributes its own registry entry from its own host file. Machines the
repository does not own (`oci-melb-1`, `home-forge`, `la-admin-1`) and the
service endpoint map are fleet facts, not host facts, and are declared once in
`modules/policy/topology.nix` beside the schema — they must not be listed in a
host file that could later be retired. Because `topology.hosts` is an attribute
set of submodules, contributions merge with no duplication and no ordering.

What changes is the reader. A flake-level value can be closed over by a
flake-level aspect, which is why `config.topology.hosts.arch.primaryUser`
never belonged in a reusable feature. Reusable features read a per-evaluation
record instead; only genuinely fleet-aware features continue to consume the
registry, and they consume it as a screen-level fleet value that is identical in
every evaluation.

### D2. A new typed `currentHost` option, declared once per class

`modules/policy/topology.nix` publishes `flake.modules.<class>.current-host`
declaring `options.currentHost` for `nixos`, `homeManager`, and
`systemManager`. One declaration, three classes, one schema — the same record
shape wherever a host evaluation runs.

Each host composition sets the record inside its own module lists. The value is
built in the host file from the registry entry it already owns:

```nix
# modules/hosts/arch.nix
let
  hostId = "shrub";
  registered = config.topology.hosts.${hostId};
  currentHost = {
    id = hostId;
    inherit (registered) primaryUser;
    peers = lib.removeAttrs config.topology.hosts [ hostId ];
  };
in
{
  flake.systemConfigs.arch = ... modules = [ ... { inherit currentHost; } ... ];
}
```

This keeps the projection at the composition boundary: the host file is the only
place that knows which registry entry it selected, and it subtracts itself once.
No feature performs a self-lookup.

### D3. The projection carries only what Nix does not provide

`currentHost` holds:

- `id` — the stable machine identity, equal to the registry key. Distinct from
  `networking.hostName`, which is a mutable OS-level label.
- `primaryUser = { name; uid; gid; }` — the human account on a machine this
  repository owns; system-manager cannot create users declaratively, so this is
  data rather than a derivation of state.
- `peers` — the registry minus the current machine, so no feature filters by
  self and `Host` blocks, mux domains, and journal pickers never alias the
  machine they run on.

Deliberately absent: architecture, home path, hostname, state version. Those
have native homes and are read from them.

### D4. Native module facts take precedence over custom records

| Fact | Source after this change |
|---|---|
| `networking.hostName` | the host's raw NixOS module, not the shared foundation aspect |
| `system.stateVersion` | the host's raw NixOS/Home Manager modules |
| build architecture | `pkgs.stdenv.hostPlatform.system` |
| home path, username | `home.username`, `home.homeDirectory` |

The shared NixOS foundation aspect keeps only the account and group creation
that the registry's `primaryUser` drives, and stops restating the hostname and
state version that the host file already declares.

### D5. Fleet-aware features consume the registry, not the projection

`ssh.nix`, `shell/wezterm.nix`, `dev-tools/lazyjournal.nix`, and the builder
declaration in `nix.nix` stay flake-level readers: they need the fleet, the
value is fleet-scoped, and it is identical in every evaluation. `peers` is a
projected convenience for the same data, so a feature never needs to know its
own name to filter itself out.

Service endpoints (`topology.services.*`) are unchanged and remain flake-level
reads: `niks3.nix` and `agents/litellm/default.nix` keep working as they are.

### D6. `sshUser` per machine replaces the flat `remoteHosts` list

A blanket `User = "dev"` is right for the build and admin boxes and wrong for
machines owned by this repository, where the login is `saurabhj`. The registry
entry gains `sshUser`, the aliases are generated per machine from the registry,
and `remoteHosts` is deleted rather than kept as a parallel list that must be
maintained twice.

### D7. Host literals leave shared aspects

`modules/foundation/boot.nix` embeds the desktop's disk: a Limine kernel command
line, a dracut drop-in, and the root subvolume UUID. Those move to
`modules/hosts/arch/_system.nix`. The shared system-manager boot aspect keeps
only behaviour that any Arch host would want, which is what makes it reusable
when a second Arch machine ever exists.

### D8. Registry keys are machine IDs; output names stay put

The registry key becomes `shrub`, matching the machine and its
`networking.hostName`, while `flake.systemConfigs.arch` and the switch command
`system-manager switch --flake .#arch` are untouched. `arch` described an OS, not
a machine, and machine identity is what the registry is for. The output rename
is already owned by `nixos-dual-boot-install`, so this change does not pull that
work forward.

### D9. Aspects stay plain aspects

Every affected feature keeps publishing `flake.modules.<class>.<aspect>` and
stays selectable by name from `config.flake.modules.<class>` in host
composition. No aspect becomes a factory taking host data, no aspect is cloned
per host, and no feature imports a topology or host file.

## Alternatives Considered

- **Fleet facts in a host file.** Leaving non-owned machines and service
  endpoints in `modules/hosts/arch.nix` keeps them declared by a host that does
  not own them, and retires them with that host. Rejected in favour of
  fleet-scoped declaration beside the schema.
- **Flat fleet record, no host key.** Smallest diff, but it collapses per-host
  identity into fleet-wide values and cannot express a second machine's own
  primary user or peer set. Rejected: it optimises for today's single host.
- **Host-keyed map injected per class wholesale.** Features would receive every
  machine and have to identify themselves to pick their own entry — ambient
  self-awareness spread across features. Rejected in favour of a projection
  computed once at the composition boundary.
- **Per-host aspect clones (`flake.modules.nixos.shrub-ssh`).** Rejected by the
  dendritic pattern's own anti-pattern guidance on lower-level module name
  proliferation, and it makes every new host re-clone the tree.
- **Aspect factories taking `host` as an argument.** Rejected: the published
  value stops being a module, `imports` lists silently misbind, and it
  reintroduces an argument bus under a new name.
