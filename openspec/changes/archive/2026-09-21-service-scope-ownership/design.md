# Design — service scope ownership

## Decisions

### D1. The Surge daemon is a user service

The daemon writes downloads, so the process that writes them should be the
account that owns the destination. That is the same rule litellm and grist
already follow in this repository, and it is what makes the unit identical on
NixOS and on the Arch host: Home Manager owns it, so the embedded Home Manager on
the NixOS target runs it without a second definition.

Rejected: a system unit on both hosts (the spec's current shape, extended with a
`flake.modules.systemManager.surge`). It keeps a root process writing files the
user then opens, needs `--output` pointed at a service-owned directory the user
does not normally look at, and would have to be written twice — once per class.

### D2. Upstream ships no unit to reuse

Verified before deciding to hand-roll:

- The nixpkgs package output contains no `.service` file
  (`pkgs/by-name/su/surge-downloader`).
- The upstream repository has no bundled unit either — its `packaging/`
  directory holds only AppImage assets, and there is no `contrib/`, `deploy/`, or
  `systemd/` directory.
- `surge service install` writes a unit at runtime into `/etc/systemd/system`,
  which is imperative state outside the store — never usable declaratively.
- Upstream's flake does publish `nixosModules.default`, which our module comment
  already rejects: it injects its own overlay (`nixpkgs.overlays = [ self.overlays.default ]`) while exposing no package option, so adopting it would
  put a second `surge` package next to the nixpkgs one this repository pins. It
  also only offers the system-scope unit decided against above.

So the declarative unit is necessarily ours. Two consequences worth recording:

- Upstream's system unit passes `--is-system-service`; the hand-rolled unit it
  replaced did not, so it was never even equivalent to upstream's shape.
- Omitting that flag is correct for a user service: config and auth token live in
  the user's own config directory, where `surge token`, the TUI, and the browser
  extension all read them.

### D3. One GC owner per host scope

`nh clean all` collects the system profile and user generations; `nh clean user`
collects only the current user's. Enabling both on one host would put two owners
on the same resource, so the split follows the scope that can actually do the
work:

- NixOS: `programs.nh.clean` (system unit, root, `nh clean all --keep-since 7d`),
  selected through the `nix` NixOS aspect.
- Non-NixOS host: the existing Home Manager timer (`nh clean user --keep-since 7d`), gated on `targets.genericLinux.enable` — the native Home Manager option
  that already expresses "this Home Manager is not running on NixOS", and the same
  discriminator `modules/desktop/noctalia.nix` uses for its pkexec path.

The gate is a platform fact read from a native option, not a host key and not a
new argument bus, so the shared aspect stays identical in every evaluation.

Only the parent `programs.nh.clean` is set on the NixOS side: `nh` itself stays a
user tool installed by Home Manager, and the timer uses the package `cfg.package`
already points at.

### D4. Arch keeps no system-side timer

system-manager has no `nix.gc` and no nh module, so parity on the Arch system
profile would mean hand-rolling a root timer in the `nix` systemManager aspect.
The user chose to leave it: the Arch system profile is collected manually.
Recorded here so the asymmetry is a decision rather than an oversight.

## Verification

- `nix eval .#homeConfigurations.saurabhj.config.systemd.user.services.surge.Service.ExecStart`
  → `surge server start --port 1700 --output /home/saurabhj/Downloads` (Arch).
- `nix eval .#nixosConfigurations.shrub.config.home-manager.users.saurabhj.systemd.user.services.surge.Service.ExecStart`
  → the same command (NixOS desktop, previously absent).
- `nix eval .#nixosConfigurations.shrub.config.systemd.services.nh-clean.script`
  → `exec …/nh clean all --keep-since 7d`.
- `nix eval .#homeConfigurations.saurabhj.config.systemd.user.services.nh-clean.Service.ExecStart`
  → `…/nh clean user --keep-since 7d`, and the same timer disabled inside the
  NixOS embedded Home Manager.
- `nix flake check --no-build --no-write-lock-file`.
