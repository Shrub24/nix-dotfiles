# Design

## Context

See `proposal.md`. Baseline: nix-fleet `23411143` and Vector 0.58.0. Nothing here is implemented; re-verify against whatever fleet revision is pinned when this change starts. The metrics change supplies the contributor, destination resolution pattern, notify checks and runbook this change extends.

## Decisions

### 1. Destination and sink

Resolve `victorialogs/jsonline` over `tailnet` in the contributor's flake-parts scope and set `services.telemetry.journald.sink.endpoint`. Journals use their own sink, not a telemetry destination or the trace gateway.

### 2. Exact system-unit allowlist

Set `journald.enable = true` with full unit names:

- `sshd.service`
- `NetworkManager.service`, `systemd-resolved.service`, `tailscaled.service`
- `nix-daemon.service`, `fast-nix-gc.service`, `nix-gc-roots.service`
- `beszel-agent.service`, `notify.service`, `prometheus-node-exporter.service`

Legion adds `snapper-timeline.service`, `snapper-cleanup.service`, `syncthing.service` in its host policy. Verify membership against built units; do not silently filter missing names.

Excluded: greeter and Home Manager activation (broader output than daemon health; adding either needs a content review), NikS3 units (names unsettled), user managers, desktop units, `init.scope`, forwarders' own logs. The trusted match is `_SYSTEMD_UNIT`, not a logger tag. Matching is exact and case-sensitive: no globs or template instances. It is narrower than `journalctl -u`: PID 1 lifecycle records about a service belong to `init.scope`, so the lane carries services' own output while notify covers failure transitions. A user-service name cannot be selected individually; selecting `user@<uid>.service` sweeps all user services.

An allowlist is not redaction. Selected logs can carry usernames, addresses, SSIDs, VPN details, paths or application errors; buffers hold copies; notify's event policy separately includes journal excerpts by default. Removing a unit stops future selection, not queued or stored copies.

### 3. Backend data policy gate

Before the first journal-enabled switch, reference the backend owner's policy for read/write access, retention, deletion and backups, plus local queue and snapshot retention. Missing evidence blocks the switch. Do not invent retention periods or widen backend permissions.

### 4. History and buffering policy

Set `current_boot_only = true` and `since_now = true` through native `services.vector.settings.sources.journald` fields, merging only those and validating with the pinned Vector binary, unless a typed fleet option exists by then. A saved cursor beats `since_now` on restart. Filtered-out entries advance the cursor, so later allowlist additions do not backfill. Unread previous-boot entries are not recovered even if journald retains them; cross-boot replay is a separate reviewed change.

Buffer: `/var/lib/vector`, 512 MiB, `whenFull = "block"`, which stops reading and relies on journald retention. Retries and checkpoint replay can duplicate lines; snapshot rollback can rewind state. No exactly-once or lossless claim.

### 5. Vector health

Use Vector's native `internal_metrics` source with a loopback `prometheus_exporter` sink on `127.0.0.1:9598`, registered as `services.telemetry.scrape.vector-health` with explicit host instance label, through the metrics pipeline. Check port collisions and the pinned series for backlog, errors and drops. Prefer a provider-owned registration if upstream supplies one.

### 6. Verification

Extend the policy checks: non-empty exact membership against built units, no user-manager inclusion, explicit history policy, effective Vector failure hooks, negative cases for empty list, missing unit, template pattern and user-manager inclusion. Runbook categories: a unique marker from an allowed unit appears with unit identity; excluded-system and user-service markers are absent after the positive path delivers (use a temporary allowlisted probe, then restore, never `logger -t`); a disposable journal/VM fixture covers first enable, same-boot restart, reboot with unread records and a rotated cursor; short outage and restart below capacity.

## Risks

- **Sensitive payloads** → narrow list, policy gate, no redaction claim.
- **Unread-history loss across reboot** → documented, explicit policy.
- **Unit-name drift** → built-unit check.
- **Upstream moves the contract** → re-verify and prefer typed options; do not carry local overrides longer than needed.

## Migration Plan

1. Start only after the metrics change is accepted on Legion and upstream has dispositioned replay policy and Vector health.
2. Implement and build Legion; review the allowlist, history policy and backend evidence; switch with explicit approval; verify.
3. Spectre when reachable and enrolled.
4. Roll back by removing the journal selection and switching; keep queues until disposal is deliberate.
