## Why

The fleet has one machine. An HP Spectre x360 13-aw0039TU joins it as the
portable NixOS host: the machine that travels, that is reached over ssh/mosh/
tailscale, and that is the first bare-metal NixOS install — the low-risk pilot
before the desktop's own cutover, because nothing on it has to survive. It is an
Ice Lake i5-1035G4 with 8 GB of soldered memory, a small SSD, Intel Wi-Fi 6
AX201, and a fingerprint reader upstream libfprint does not support.

Depends on `current-host-facts`: the shared aspects must be host-agnostic before
a second host can select them.

## What Changes

- Add `modules/hosts/spectre.nix` composing `flake.nixosConfigurations.spectre`
  from a lean aspect set: the full interactive environment (niri, noctalia,
  vicinae, portals, fonts, libinput, audio, kde-apps) plus terminals, CLI/dev
  tooling, agent CLIs, browsers, ssh/mosh/tailscale, and sops/credentials — and
  none of the local service tier (grist, docs-mcp, hermes, qmd,
  web-catalog, syncthing, surge, niks3, monique, mutagen, modal, cuda,
  libcamera). Those stay on the desktop and `home-forge`; the laptop's clients
  point at them.
- Add the host's raw modules: `_nixos.nix` (hostname, state version, locale,
  timezone), `_home.nix` (identity and the lean home), `_hardware.nix`
  (generated on install day and hand-edited down, per the repository
  convention).
- Split distributed-builder selection out of the `nix` aspect into its own
  aspect, selected by the desktop and not by the laptop, so the laptop needs no
  root build key and holds no system secret in v1. It substitutes from
  `cache.shrublab.xyz`, nix-community, and numtide and builds locally.
- Register the laptop in the fleet registry (`topology.hosts.spectre` with
  `system`, `sshUser`, `primaryUser`) and give the desktop registry entry its
  login user, so peer aliases, mux domains, and the journal picker include it.
- Portable hardware: Intel microcode, thermald, `power-profiles-daemon`,
  hp-wmi battery charge threshold, bluetooth, Sound Open Firmware for the ALC285
  codec, and Thunderbolt authorisation for the two USB-C ports. The fingerprint
  reader is unsupported upstream and is left disabled with the finding recorded
  in the host file.
- Storage: 1 GiB ESP plus one LUKS2 container covering the rest of the disk,
  TPM2 enrolled beside the passphrase, btrfs subvolumes (`@`, `@nix`, `@home`,
  `@swap` NOCOW), and a 12 GiB swapfile with `resume_offset` for hibernation.
  Single boot: nothing reserved for another operating system.
- Secrets bootstrap in two phases: install with no secret-consuming aspect, then
  generate the laptop's own age key, add it as a recipient in `.sops.yaml`,
  re-encrypt with `sops updatekeys`, and switch a second time. The private key
  never transits the network, and no other machine's key is copied to it.
- Validation: the laptop's NixOS toplevel joins the flake checks, and a boot
  level VM check covers its aspect composition so a module conflict is found
  before install day.
- Update `README.md`, `ARCHITECTURE.md`, and the spec index for the second host.

## Capabilities

### New Capabilities

- `spectre-host`: the portable NixOS host — its composition, hardware profile,
  storage and encryption layout, secrets bootstrap, remote access posture, and
  validation.

### Modified Capabilities

- `secrets-ownership-model`: secrets become host-scoped — each machine decrypts
  with its own age key, and recipients are declared per machine.

## Impact

- New: `modules/hosts/spectre.nix`, `modules/hosts/spectre/_nixos.nix`,
  `modules/hosts/spectre/_home.nix`, `modules/hosts/spectre/_hardware.nix`.
- Modified: `modules/hosts/arch.nix` (registry entry, checks),
  `modules/policy/topology.nix` (the laptop entry), `modules/nix.nix` (builder
  aspect split), `.sops.yaml` (recipient), the four encrypted secret files
  (re-encrypted in place), `README.md`, `ARCHITECTURE.md`.
- New machine-side state: one LUKS2 container and one TPM2 enrolment on the
  laptop, and one host-scoped age key at the user's key path.
- No change to the desktop's runtime behavior, and no new flake input.
