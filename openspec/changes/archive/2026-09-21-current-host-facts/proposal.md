## Why

Every reusable feature in this repository reads host facts from a single
flake-level value, `config.topology.hosts.arch`. Flake-parts evaluates that once
for the whole flake, so every aspect value built from it is single-host by
construction: a second machine would either duplicate aspects or read the
desktop's identity. The repository needs host-agnostic features before a second
host can be added.

## What Changes

- Keep the typed global registry (`topology.hosts.<name>`, `topology.services.<name>`)
  at the flake-parts level as the fleet's single source of truth, and give each
  machine entry the login user used to reach it (`sshUser`). The flat
  `remoteHosts` list becomes a derived view of the registry instead of a
  hand-maintained duplicate.
- Introduce one typed `currentHost` option, declared once and published for all
  three classes (NixOS, Home Manager, system-manager), holding only the
  semantics Nix does not already provide: stable machine ID, primary user, and
  the peer machines.
- Each host composition SHALL select its own registry entry once and project
  that record into its own module lists through the normal module system — never
  through `specialArgs`/`extraSpecialArgs`, and never by having a feature module
  import a host file.
- Replace `config.topology.hosts.arch.*` reads in reusable aspects with
  `config.currentHost.*` (greeter, noctalia, desktop-services, syncthing, nix,
  boot) or with native module facts where those already exist.
- Prefer native facts: drop the duplicated `networking.hostName` and
  `system.stateVersion` from the shared NixOS foundation aspect (the host's raw
  module already owns both values) and read the build architecture from
  `pkgs.stdenv.hostPlatform.system`.
- Move the Arch-only boot literals (Limine kernel command line, dracut drop-in,
  root subvolume UUID) out of the shared system-manager boot aspect into
  `modules/hosts/arch/_system.nix`, where the machine that owns the disk lives.
- Rename the registry key `arch` to the machine ID `shrub` — identity, not OS
  label or output name. Flake output names (`.#arch`, `.#shrub`) are unchanged;
  the desktop's output rename stays with `nixos-dual-boot-install`.
- **No evaluated behavior changes**: the Arch Home Manager activation, the
  system-manager configuration, and the NixOS toplevel SHALL evaluate to the
  same systems as before.

## Capabilities

### New Capabilities

- `current-host-facts`: how a host evaluation receives its own typed identity
  record, and how reusable features consume it instead of a flake-wide topology
  key.

### Modified Capabilities

- `dendritic-module-composition`: shared host data is projected into each
  evaluation rather than read at flake level, and native module facts take
  precedence over custom records.
- `ssh-client`: host alias blocks derive from the machine registry with a
  per-machine login user instead of a blanket user override.

## Impact

- `modules/policy/topology.nix` — registry schema and the `currentHost`
  declaration for all three classes.
- `modules/hosts/arch.nix` and `modules/hosts/arch/_system.nix` — registry entry,
  projection, relocated boot literals.
- Reusable aspects updated to read the projection or native facts:
  `foundation/nixos.nix`, `foundation/boot.nix`, `desktop-services.nix`,
  `desktop/greeter.nix`, `desktop/noctalia.nix`, `syncthing.nix`, `nix.nix`.
- Fleet-aware aspects updated for the registry typing:
  `ssh.nix`, `shell/wezterm.nix`, `dev-tools/lazyjournal.nix`.
- No secrets, no new flake input, no new host, no runtime behavior change.
