# Design — Portable Host (`spectre`)

## Context

The repository has one machine and a NixOS target that has never been installed
on bare metal. The laptop is the cheaper of the two machines to get wrong, so it
takes the NixOS install first: nothing on it needs preserving, and a failed
install costs a reinstall rather than a working desktop.

The machine is an HP Spectre x360 13-aw0039TU: Ice Lake i5-1035G4 with Iris Plus
graphics, 8 GB soldered LPDDR4, a small NVMe SSD (256 GB as shipped), Intel
Wi-Fi 6 AX201, a Realtek ALC285 codec that requires Sound Open Firmware, TPM 2,
two Thunderbolt 3 ports, and a Synaptics fingerprint reader that upstream
libfprint does not support.

`current-host-facts` (prerequisite) removes the last single-host assumption from
the shared aspects. This change adds the host itself: composition, hardware
profile, storage layout, secrets bootstrap, and the install runbook.

## Goals / Non-Goals

**Goals:**

- A daily-drivable portable NixOS host: interactive desktop, terminals, CLI/dev
  tooling, agent CLIs, browsers, and remote access, with no local service tier.
- A storage layout that supports hibernation without reserving space the
  machine will never use.
- A secrets bootstrap that cannot half-fail: the first switch never needs a key
  that does not exist yet.
- Findings before install day: a VM check that boots the laptop's aspect
  composition, and a toplevel that builds in CI.

**Non-Goals:**

- Copying the desktop's service tier to the laptop. Grist, docs-mcp,
  hermes-agent, qmd, web-catalog, Syncthing, the niks3 uploader, Monique, CUDA
  and libcamera stay on machines that are always on.
- Distributed builds on the laptop. Root would need an ssh key for a builder,
  which makes it the first system secret on a portable machine. Substituters
  cover the common case; revisiting is a later change.
- Windows on this machine. The laptop is single-boot; the desktop remains the
  fleet's only Windows candidate.
- Secure Boot / lanzaboote. It stays off, which is also what keeps the TPM2
  keyslot stable.

## Decisions

### D1. NixOS-only host, no system-manager counterpart

The laptop runs NixOS, so it contributes `flake.nixosConfigurations.spectre` and
nothing else: no `systemConfigs` output, no standalone `homeConfigurations`
output, and no `targets.genericLinux` — that discriminator and the standalone
Home Manager output both exist for the Arch host, where there is no system to
build. On a NixOS-only machine the embedded Home Manager is the only
configuration path, so an update is one `nixos-rebuild` and there is no second
activation route to keep in sync. The desktop keeps both classes until its
cutover.

### D2. Lean aspect set: full environment, no local services

Home Manager aspects: niri, noctalia, portals, fonts, libinput, audio,
pavucontrol, kde-apps, util-apps, defaults; shell, fish, tmux, wezterm, kitty,
foot; cli, dev-tools, lsp, nvim, languages, mise, direnv, intelli-shell,
lazyjournal; pi, herdr; firefox, thunderbird, zathura; sops-foundation,
credentials, ssh, mosh, tailscale, nix.

NixOS aspects: foundation, network, boot, ssh, tailscale, greeter, nix, audio,
bluetooth, power, containers, desktop-services, kde-apps, mosh.

Three deliberate constraints shape the profile. The local service tier is absent
because every service is a machine that is always on doing the job instead: the
desktop runs them, the `hermes`/`aichat` clients are pointed at `home-forge`, and
knowledge services stay where their state lives. No Chromium-class browser beyond
Firefox and no Electron editor is selected: a second and third browser plus VS
Code would cost more memory than 8 GB of soldered RAM can spare, and on this
machine memory is the binding constraint rather than disk. Nothing media- or
office-heavy is selected either — `media` and LibreOffice stay on the desktop.

One shell and one agent surface are deliberate. `fish` is selected and `zsh`
with its abbreviation aspect is not: two configured interactive shells on a
machine whose sessions are mostly other machines' keeps a second startup path
alive for no benefit, and fish already carries the shared abbreviation table. The
agent surface is `pi` plus `herdr` — the interactive coding agent and the
terminal multiplexer its panes live in. `opencode` (a second agent CLI) and the
agent-tool package set (a codebase indexer, a document extractor, a search CLI)
are not selected: they serve agent workflows that run against a repository
checkout, which is the desktop's job. The ssh reattach convenience the desktop
expresses in its zsh config is expressed for fish in the host's own `_home.nix`
rather than inherited.

What stays is what a travel machine is for. `kde-apps` provides the GUI file
manager that niri's own `Mod+E` binding spawns, along with KDE Connect and the
image, archive, and PDF viewers; `util-apps` keeps the manual theming tools
(`matugen` generates the icon pack outside Nix); `audio` keeps the EQ, which
matters on a two-speaker laptop. Starting lean is deliberate — an aspect added
later is one import line, an aspect removed after it has written state is a
migration.

### D3. Builder access is selected, not inherited

`modules/nix.nix` currently declares `nix.distributedBuilds` and the
`home-forge` build machine inside the shared `nix` aspect, which every NixOS host
would inherit along with its requirement that root hold
`/root/.ssh/nix-remote`. The builder declaration moves into its own aspect that
the desktop selects and the laptop does not. Importing an aspect enables the
feature it provides — the laptop not importing it is the whole mechanism, and no
`enable` option is introduced.

### D4. Hardware profile follows the confirmed model

This is an Ice Lake machine, not the 8th/9th-generation guess it started as, and
the confirmed device list fixes most of the profile before anything is probed:

| Device                                 | Handling                                                                                                                                            |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| i5-1035G4 (Ice Lake)                   | `hardware.cpu.intel.updateMicrocode`; `thermald` — this generation runs warm                                                                        |
| Iris Plus G4 (8086:8a52)               | `hardware.graphics.enable` plus the Intel VA-API driver; no dGPU, no PRIME                                                                          |
| Wi-Fi 6 AX201 (8086:34f0)              | `iwlwifi` firmware via the redistributable-firmware path                                                                                            |
| Realtek ALC285 (8086:34c8)             | requires Sound Open Firmware: `hardware.firmware = [ pkgs.sof-firmware ]`                                                                           |
| Synaptics touchpad (06cb:cd50)         | `libinput` only                                                                                                                                     |
| Elantech touchscreen + pen (04f3:29f9) | works; pen buttons are imperfect upstream                                                                                                           |
| Realtek card reader (10ec:525a)        | works unconfigured; the microSD slot is spare storage                                                                                               |
| Two Thunderbolt 3 ports                | `services.hardware.bolt.enable` for dock authorisation                                                                                              |
| TPM 2                                  | required by the LUKS2 keyslot plan in D5                                                                                                            |
| Synaptics fingerprint (06cb:00c9)      | **not supported**: upstream libfprint has no driver, only a reverse-engineering fork — no `fprintd`, recorded as a host-file comment                |
| Accelerometer                          | `iio-sensor-proxy`; note that auto-rotation needs a userspace agent, which niri does not provide, so it is optional rather than part of this change |
| Battery                                | zram plus the hibernation swapfile (D5); hp-wmi charge threshold where the firmware exposes it                                                      |

Only three things still need the machine itself: the SSD's real capacity, the
ESP's size and the disk's identifier by serial/WWN, and whether the fingerprint
reader's USB id matches the documented `06cb:00c9`.

### D5. One LUKS2 container, btrfs inside, the whole disk spoken for

Partition plan, fixed before anything is written to disk:

| #   | Size      | Purpose                                                       |
| --- | --------- | ------------------------------------------------------------- |
| 1   | 1 GiB     | ESP, vfat, mounted `/boot`                                    |
| 2   | remainder | LUKS2 container holding btrfs (`@`, `@nix`, `@home`, `@swap`) |

Two partitions, nothing unallocated. The ESP is 1 GiB because kernels and
initrds live on it, not because firmware wants the space: at roughly 50 MB per
generation a 512 MiB ESP runs out once a few generations accumulate, and
`boot.loader.systemd-boot.configurationLimit` is a worse answer than starting
with room.

Subvolume layout mirrors the desktop (`@` root, `@nix` separate, `@home`), plus
`@swap`: a NOCOW subvolume holding one 12 GiB swapfile (8 GiB of memory plus
4 GiB of headroom for hibernation). Hibernation on btrfs needs `resume_offset`
from `btrfs inspect-internal map-swapfile -r <swapfile>` because the swapfile is
not at a fixed physical offset. A `@snapshots` subvolume is created only if
Snapper is adopted later; creating it afterwards costs nothing. The alternative —
a second LUKS-encrypted swap partition — avoids the offset bookkeeping but adds a
second device and a second TPM2 enrolment; it remains the fallback if resume
proves unreliable on this firmware.

TPM2 is enrolled with `systemd-cryptenroll` alongside the passphrase, so boot is
silent and a firmware reset or a changed PCR set degrades to a passphrase prompt
rather than a lost install.

### D6. Single boot

The laptop is NixOS-only. No space is reserved, no NTFS handling exists, and the
boot entry stays undeclared until there is something to point it at. The hedge
was expensive on a small disk — holding roughly a third of the storage idle to
cover a need the desktop's own dual-boot plan already covers — and each extra
partition is another thing to get wrong on a machine whose purpose is to be
carried around and reinstalled without ceremony.

The accepted cost is explicit: adding Windows here later means shrinking btrfs,
moving the container's end, and creating the partition — the exact operation the
reservation existed to avoid. It is now a problem for the day the need is real,
rather than 80 GiB paid up front.

### D7. Secrets are host-scoped and the bootstrap is two-phase

Phase 1 installs and switches with `sops-foundation`, `credentials`, and the
GITHUB_PAT-backed part of the `nix` aspect left out, because sops activation
fails when no key can decrypt and a first switch that fails is indistinguishable
from a broken install.

Phase 2, after the machine boots:

1. Generate the host's own age key on the laptop.
1. Read the public key off the laptop and add it as a recipient in `.sops.yaml`.
1. Re-encrypt every secret file with `sops updatekeys` from the desktop, which
   still holds the owner key.
1. Add the secret-consuming aspects to the laptop's composition and switch again.

The private key is generated on the laptop and never leaves it; no other
machine's private key is copied to it. The laptop holds no system secret in v1
because D3 removes the builder key.

### D8. Remote access is the point of the machine

`services.openssh` with password authentication off, mosh, and tailscale, all
selected through the existing aspects. The laptop is reachable by tailnet name
and appears in the desktop's peer set, so `ssh spectre`, `mosh spectre`, mux
domains, and the journal picker all work without any per-machine configuration
outside the registry entry.

### D9. Validation happens before the machine exists

The laptop's toplevel joins the flake checks, and a boot-level VM check
(`vm-spectre-boot`) composes the laptop's NixOS aspect set with a minimal VM
hardware stanza, mirroring what `vm-skeleton-boot` already proves for the
desktop. Eval-only checking has already been proven insufficient in this
repository; a module conflict discovered on the laptop at 11 pm is not.
`vm-spectre-boot` runs headless — no greeter, no graphical assertions.

### D10. Documentation moves with the host

`README.md` gains the switch command and the second machine; `ARCHITECTURE.md`
gains the second host in the overview, the composition tree, and the service
lifecycle section; the spec index gains `spectre-host`.

## Alternatives Considered

- **Full desktop parity on the laptop.** Rejected: it puts always-on services on
  a machine that sleeps, travels, and will be wiped by its next owner.
- **Arch + system-manager on the laptop for consistency with the desktop.**
  Rejected: a fresh install is the moment NixOS costs nothing, the NixOS aspects
  already exist, and the laptop is the cheapest place to prove them.
- **disko for declarative partitioning.** Rejected for now: it adds an input and
  a second source of truth for the same disk beside `_hardware.nix`, for an
  install that happens once.
- **Reserving space for a Windows install that may never happen.** Rejected: on
  a 256 GB disk the reservation idles a third of the storage to hedge a need the
  desktop can cover, and the cost of adding Windows later is a resize rather than
  a reinstall.
