# Proposal — Settle the configuration after the NixOS transition

## Why

Legion now runs NixOS and Arch is no longer a target. The cutover left debt
that no single change owns: transitional gates that can never flip back,
modules whose shape was chosen for Arch or for an upstream that has since
moved, open tasks on changes whose work already happened, and nix-fleet
capabilities that landed after the local modules were written. This change
maps all of it in one place so each item is either done, dropped, or
deliberately kept. Nothing here is implemented yet, and all of it is phase 2:
it starts after the soak and full error check, once Arch is decommissioned.

## What Changes

Each group is a candidate, not a commitment; an item that turns out to be
wrong is struck from the tasks with its reason.

- **Remove gates that are permanently open.** Legion's `sshIdentitiesEnrolled`
  and Spectre's `secretsEnrolled` phase machinery, plus the unenrolled
  fallback paths and runbook branches they exist for, once Spectre has been
  enrolled.
- **Stop selecting aspects only to subtract them.** Legion lists the Home
  Manager `tailscale`, `syncthing`, `mosh` and `niks3` aspects and then removes
  them again in `embeddedHmAspects`; with no standalone Home Manager output,
  the selection and the subtraction both go.
- **Adopt nix-fleet capabilities the local modules predate.**
  - `telemetry`: `modules/telemetry.nix` re-exports the fleet aspect but no
    host selects it and nothing registers a scrape source or an OTLP producer.
    Decide whether any host should run the collector (and where it sends),
    or drop the pass-through.
  - `build-account`: drop the transitional `dev` dispatch account once
    nix-homelab selects it on home-forge (`policy/fleet.nix`).
  - `notify` registration for the snapper timers (open task in
    `migrate-home-to-data-disk`).
  - The `podman` aspect stays declined while nixpkgs defines `podman-prune`
    unconditionally; revisit if either side changes.
- **Re-check local modules against their reason for existing.** `surge` is a
  user-scoped Home Manager unit because the upstream flake module installs an
  overlay and writes its unit outside the store; confirm that still holds for
  the pinned version. `boot.kernelPackages = linuxPackages_latest` lost its
  Arch-era rationale. Legion's hand-listed initrd modules can shrink to
  overrides over the facter report. Early `i915` KMS is a one-line option.
- **Pay down residual Arch traces.** The `saurabhj@arch` key comment, unmanaged
  `~/.config/uwsm/env`, `~/.bash_profile` and `~/.profile`, and the Google
  OAuth client for the retired vdirsyncer.
- **Reconcile open OpenSpec tasks with what happened.**
  `add-spectre-host` sections 3–6, `migrate-home-to-data-disk` (notify
  registration, `/home` eval assertion, uv reflink check, rollback),
  `snapper-snapshots` verification, and `migrate-agent-configs-to-nix` 4.3 and
  5.6. `nixos-dual-boot-install` section 7, the destructive root grow, stays
  open until the owner ends the soak deliberately.
- **Fix two stale lines** in `docs/runbooks/enroll-legion-identities.md` that
  still describe system-manager and the Arch sshd.

Deferred decisions carried from earlier sessions: Avahi publishing against the
single-mDNS-responder arrangement, disk-backed `/tmp` policy after the first
soak, impermanence and its bootstrap-key ordering, local Ollama and CUDA SDK
environment, the extra `~/.ssh/home-forge-dev` identity, and KDE Connect
screen sharing.

## Impact

Mostly deletions and one-line option changes in `modules/hosts/`,
`modules/telemetry.nix`, `modules/surge.nix` and the runbooks, plus task
bookkeeping across five existing changes. Any adoption of `telemetry` adds a
destination and a credential and needs its own design first.
