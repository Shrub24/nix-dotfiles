Phasing. The soak and the full error check come first, then Arch is decommissioned once parity is established and every failure mode is covered. Everything below is phase 2 and starts after that; none of it gates the soak. Section 6 holds the capabilities that were evaluated and deliberately deferred.

## 1. Gates and selection

- [x] 1.1 Delete `sshIdentitiesEnrolled` and the unenrolled branches in `modules/hosts/legion.nix`, `legion/ssh-identities.nix` and both runbooks.
- [x] 1.2 Delete the `secretsEnrolled` phase lists in `modules/hosts/spectre.nix`.
- [x] 1.3 Drop the Home Manager `tailscale`, `syncthing`, `mosh` and `niks3` selections that `embeddedHmAspects` subtracts, and the subtraction.

## 2. Upstream adoption

- [ ] 2.1 Adopt the fleet observability baseline (contract re-read 2026-10-08, nix-fleet `docs/contracts/observability.md`). The catalog now publishes all three write routes on home-forge, reachable from legion on the tailnet: traces `otel-collector.otlp` (`:4318`), metrics `victoriametrics.remote-write` (`:8428/api/v1/write`) and journals `victorialogs.jsonline` (`:9428/insert/jsonline`). Lanes, in adoption order, each resolved through `serviceEndpoints` in the host's flake-level module and passed to the NixOS aspect as a value: (a) `node-exporter` beside `telemetry`, with one `prometheus-remote-write` destination for metrics; (b) journal shipping with an explicit unit allowlist (the policy requires it on workstations; an empty `includeUnits` ships everything and does not qualify), starting from `sshd`, `NetworkManager`, `tailscaled`, `nix-daemon`, `fast-nix-gc`, `nix-gc-roots`, `beszel-agent`, `notify` and the units the host owns; (c) traces relay (`otlp.signals = [ "traces" ]`, one `otlp-http` destination, `resourceAttributes` carrying host identity), only once a producer exists — that needs a `pi-otel` plugin row and recipe plus an embedded-HM aspect reading `osConfig.services.telemetry.otlp.httpUrl`. Persist `/var/lib/vmagent`, `/var/lib/vector` and `/var/lib/opentelemetry-collector` if impermanence is adopted. Acceptance is the contract's seven-step list; configured, deployed and delivering are separate milestones, and a GET returning 404/405 proves none of them.
- [ ] 2.5 Bind spectre's SSH host key in nix-fleet's inventory (`publicKey` is unbound, so legion's trust set omits it); needs the laptop online to harvest the key.
- [x] 2.0 Select the fleet `nix-gc` with the `fast-nix-gc` collector on both hosts: hourly threshold collection (`ensureFree` 15%), daily root pruning, no optimise pass on btrfs.
- [ ] 2.2 Drop the `dev` build account when home-forge selects `build-account` (`modules/policy/fleet.nix`).
- [ ] 2.3 Register the snapper timer units with the fleet `notify` capability.
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
