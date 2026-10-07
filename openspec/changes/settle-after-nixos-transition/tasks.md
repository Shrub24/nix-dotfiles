Phasing. Complete the hardware cleanup, Snapper failure registration and push first; telemetry adoption is next, starting with metrics and the explicit journal allowlist. The soak and full error check still gate Arch decommission: parity and failure-mode coverage must be established before the wipe. Other phase-2 items remain deferred. Track persistence discoveries in `docs/impermanence.md`, prioritising home while root stays persistent.

## 1. Gates and selection

- [x] 1.1 Delete `sshIdentitiesEnrolled` and the unenrolled branches in `modules/hosts/legion.nix`, `legion/ssh-identities.nix` and both runbooks.
- [x] 1.2 Delete the `secretsEnrolled` phase lists in `modules/hosts/spectre.nix`.
- [x] 1.3 Drop the Home Manager `tailscale`, `syncthing`, `mosh` and `niks3` selections that `embeddedHmAspects` subtracts, and the subtraction.

## 2. Upstream adoption

- [ ] 2.1 Implement [adopt-fleet-observability](../adopt-fleet-observability/proposal.md): metrics and explicit system-service journal allowlists on both hosts, with per-host delivery evidence and state recorded in `docs/impermanence.md`. Its design and tasks own the rollout. Trace producer/relay adoption remains separate until a producer exists; no `pi-otel` or OTLP ingress is enabled by this change.
- [ ] 2.5 Bind spectre's SSH host key in nix-fleet's inventory (`publicKey` is unbound, so legion's trust set omits it); needs the laptop online to harvest the key.
- [x] 2.0 Select the fleet `nix-gc` with the `fast-nix-gc` collector on both hosts: hourly threshold collection (`ensureFree` 15%), daily root pruning, no optimise pass on btrfs.
- [ ] 2.2 Drop the `dev` build account when home-forge selects `build-account` (`modules/policy/fleet.nix`).
- [x] 2.3 Register the timer-triggered `snapper-timeline` and `snapper-cleanup` services with the fleet `notify` capability; failures belong to the services, not their scheduling timers.
- [ ] 2.4 Re-test the fleet `podman` aspect against the nixpkgs `podman-prune` unit; keep the local `autoPrune` if they still clash.

## 3. Local modules

- [x] 3.1 Upstream surge's `nixosModules.default` (checked 2026-10-07) is still not usable here: it installs a `nixpkgs.overlays` entry and runs surge as a root system service with `--is-system-service`, and its only options are `enable` and `systemd.enable` — no port, no output directory, no user. `modules/surge.nix` stays a user-scoped Home Manager unit; revisit if upstream gains those options.
- [ ] 3.2 Decide `boot.kernelPackages = linuxPackages_latest` on merit.
- [x] 3.3 Shrink legion's hand-listed initrd modules to overrides over the facter report.
- [x] 3.4 Decide early `i915` KMS.

## 4. Residual Arch traces

- [ ] 4.1 Re-key or accept the `saurabhj@arch` comment on the authorized key.
- [x] 4.2 Removed `~/.config/uwsm/env`, `env-niri` and the Arch-era `~/.bash_profile`, `~/.profile`; bash startup files and broot are now Home Manager-owned.
- [ ] 4.3 Revoke the Google OAuth client for vdirsyncer.

## 5. OpenSpec bookkeeping

- [ ] 5.1 Reconcile `add-spectre-host` sections 3–6 with the completed install.
- [ ] 5.2 Tick or drop the open items in `migrate-home-to-data-disk`, `snapper-snapshots` and `migrate-agent-configs-to-nix`.
- [ ] 5.3 Fix the system-manager and Arch sshd lines in `docs/runbooks/enroll-legion-identities.md`.
- [ ] 5.4 Rewrite the `noctalia-shell` greeter requirement (`openspec/specs/noctalia-shell/spec.md:41-69`): it still describes greeter 1.2.1, the validating root wrapper and a pkexec rule, all removed in favour of the nixpkgs `passwordlessSyncUsers` option.
- [ ] 5.5 Hold `nixos-dual-boot-install` section 7 until the owner ends the soak.

## 6. Deferred capabilities (phase 2, evaluated and held)

- [ ] 6.1 Evaluate nix-fleet's `bifrost` gateway against the OmniRoute gateway legion's LLM traffic uses today; decide whether workstations consume it or it stays server-side.
- [ ] 6.2 Adopt the fleet build-and-cache path: the reusable `build-push-cache` workflow in place of `validate.yml`'s hand-written jobs, and the niks3 publisher, once the owner calls for it.
- [ ] 6.4 Report to nix-fleet that the `tailscale` aspect declares `systemd.services.tailscaled-autoconnect` (ordering only) even when `secretFiles.auth` is unbound, so systemd refuses the unit every boot ("Service has no ExecStart=") and the `sops-install-secrets.service` it orders after does not exist here; the declaration belongs under the same condition as `authKeyFile`.
- [ ] 6.5 KDE Connect screen sharing (needs pipewire at runtime in kdeconnectd) and Avahi `publish.userServices`, weighed against the single-mDNS-responder arrangement in `modules/foundation/network.nix` before any change.
- [ ] 6.6 Optional: `sops-bootstrap` for creating new secret files from templates, if the owner wants that workflow.
