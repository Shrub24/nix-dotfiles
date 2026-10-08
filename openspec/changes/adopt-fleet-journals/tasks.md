# Tasks

Blocked until `adopt-fleet-observability` is accepted on Legion and upstream has dispositioned replay policy and Vector health. Re-verify the fleet pin first. Switches and live exercises need separate approval.

## 1. Policy and configuration

- [ ] 1.1 Resolve `victorialogs/jsonline` in `modules/telemetry.nix` and set the sink. Verify canonical URL and no trace-gateway use.
- [ ] 1.2 Implement the exact shared and Legion-only allowlists. Verify against built units, non-empty, and exclusions (user managers, `init.scope`, greeter/HM activation, NikS3).
- [ ] 1.3 Set `current_boot_only`/`since_now` (typed option if available, else native merge validated with the pinned Vector) and the 512 MiB blocking buffer. Preserve fleet-owned source, sink and permissions.
- [ ] 1.4 Register Vector health on loopback with explicit instance label; validate series and port.
- [ ] 1.5 Extend policy checks with negative cases (empty list, missing unit, template pattern, user-manager inclusion) and Vector failure hooks through notify.

## 2. Privacy and documentation

- [ ] 2.1 Obtain and reference backend access, retention, deletion and backup policy, local queue and snapshot retention, and review notify's journal-excerpt output. Verify before requesting a switch.
- [ ] 2.2 Document filtering scope, history semantics and marker procedures in the runbook; update `docs/impermanence.md` with `/var/lib/vector`.
- [ ] 2.3 Verify with a disposable journal/VM fixture: no first-enable backfill, same-boot cursor recovery, previous-boot exclusion, rotated-cursor behaviour.

## 3. Rollout

- [ ] 3.1 Format, run checks and the canonical flake check on the exact tree; build Legion; review allowlist and evidence.
- [ ] 3.2 With approval, deploy Legion; verify units, listeners, buffer path, hooks.
- [ ] 3.3 Verify positive and negative markers, health samples, and a short outage and restart below capacity; clean up probes.
- [ ] 3.4 Spectre when reachable and enrolled; repeat independently.
- [ ] 3.5 Reconcile the ledger and `settle-after-nixos-transition` task 2.1 (journal part).
