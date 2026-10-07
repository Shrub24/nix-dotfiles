# Tasks

Implementation begins only after this proposal is approved. Switches and live failure/outage exercises require separate operator approval. Keep unrelated working-copy changes out of this change.

## 1. Metrics contributor and host selection

- [ ] 1.1 Extend `modules/telemetry.nix` with flake-level canonical metrics/journal endpoint resolution and the metrics-only `fleet-metrics` destination; add `modules/node-exporter.nix` as a thin fleet import. Verify evaluated destination protocol/signals and the fleet-owned local scrape registration, without hardcoded backend coordinates or new packages.
- [ ] 1.2 Select `telemetry` and `node-exporter` in both NixOS host aspect lists. Add focused evaluation checks for provider activation, loopback-only exporter binding, distinct host instance labels and no OTLP listeners/destinations; execute the checks against both host configurations.
- [ ] 1.3 Document the metrics lane and its coexistence with Beszel in `ARCHITECTURE.md` and add the metrics/query section of `docs/runbooks/verify-workstation-observability.md`. Verify the documentation uses canonical selectors and distinguishes fresh backend samples from endpoint reachability.

## 2. System journals, failure hooks and state

- [ ] 2.1 Implement the shared allowlist and Legion-only additions from `design.md`, with `journald.enable = true`, 512 MiB buffering and `whenFull = "block"`. Verify full unit names exist in each evaluated system configuration, lists are non-empty, and user managers, desktop/user services and the unsettled NikS3 unit are not included.
- [ ] 2.2 Extend the evaluation checks to cover journal sink resolution, allowlist membership and effective fleet failure hooks for `prometheus-node-exporter`, `vmagent` and `vector` through the existing notify dispatcher/topic. Execute the check and verify registrations are not duplicated locally.
- [ ] 2.3 Add journal privacy, trusted-unit marker procedures and queue/recovery sections to the runbook. Document possible sensitive unit output, current-boot replay limits and finite retention; verify the positive/negative test restores the production allowlist and leaves no test units or overrides.
- [ ] 2.4 Update `docs/impermanence.md` with the configured vmagent/Vector paths, DynamicUser/permission caveat, 1 GiB-per-destination and 512 MiB limits, and their loss modes. Verify there is no new home persistence path or reset/mount change, and the OTel collector path remains planned rather than active.

## 3. Integration gate and Legion rollout

- [ ] 3.1 Format only owned files, execute the focused checks, and run `nix flake check --no-build --no-write-lock-file` against the exact proposed commit tree. Build Legion's toplevel; record command outcomes and review the proposed allowlist before requesting a switch.
- [ ] 3.2 After explicit switch approval, deploy Legion and record configured/deployed status, running provider units, loopback listeners, realised queue directories/permissions and effective failure hooks. Mark persistence paths active only when deployment is verified.
- [ ] 3.3 Verify Legion delivery with fresh host-labelled node metrics, an allowed system marker, and excluded-system/user markers. Have the backend owner check for duplicate remote scrapes; record uniquely identifiable evidence and clean up probes before marking these categories passed.
- [ ] 3.4 With operator approval, exercise a short destination outage plus forwarding-agent restart below capacity. Verify queued data reaches the backend after reconnection, queues drain and limits remain bounded; do not disrupt SSH/the whole tailnet or saturate production queues.
- [ ] 3.5 Obtain fleet-operator evidence for allowed/denied access to the selected backend routes, a controlled registered-unit failure and the existing alert-to-system-topic route. Record categories that cannot yet be exercised as pending; mark trace delivery not applicable, not passed.

## 4. Spectre rollout and acceptance record

- [ ] 4.1 When Spectre is reachable and its existing switch prerequisites are satisfied, build/deploy its configuration with explicit approval. Verify its own instance, smaller allowlist, provider units, storage and failure hooks; otherwise retain configured-only status without claiming deployment.
- [ ] 4.2 Repeat the positive/negative journal, fresh metrics, short-outage/restart and applicable network/notification checks on Spectre. Record per-host evidence and remove all temporary probes; Legion results do not count as Spectre results.
- [ ] 4.3 Reconcile the per-host acceptance ledger and `settle-after-nixos-transition` task 2.1. Verify both hosts satisfy the applicable categories, or record an explicitly accepted host deferral rather than silently checking off delivery. Keep future trace producer/relay adoption separate.

## Workflow follow-up

- Review the final diff and persistence inventory before committing or pushing implementation.
- Archive only after acceptance is complete or remaining external/host deferrals have been explicitly accepted.
