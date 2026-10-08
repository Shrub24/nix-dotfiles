# Verify workstation observability (metrics)

Metrics-only adoption of the fleet `telemetry` and `node-exporter` aspects on
Legion and Spectre. Journals and traces are separate changes: on these hosts
there is no OTLP listener, no gateway ingress, no Vector unit and no trace
destination to check. Use `adopt-fleet-journals` for the journal lane.

The fleet acceptance categories live in the fleet observability contract
(`docs/contracts/observability.md`, "Adoption acceptance"). This runbook keeps a
per-host ledger over the applicable ones and separates **configured**, **deployed**
and **delivering**: a resolved address, a built unit or an HTTP response is not
delivery evidence.

## What is configured where

| Piece            | Value                                                                                        | Owner                                |
| ---------------- | -------------------------------------------------------------------------------------------- | ------------------------------------ |
| Aspects          | `telemetry` + `node-exporter` in both aspect lists                                           | `modules/hosts/*.nix`                |
| Destination      | `fleet-metrics`, `prometheus-remote-write`, `victoriametrics/remote-write` over `tailnet`    | `modules/telemetry.nix`              |
| Pipeline         | `pipelines.metrics = [ "fleet-metrics" ]`, pinned                                            | `modules/telemetry.nix`              |
| Node exporter    | nixpkgs node exporter on `127.0.0.1:9100`, scrape job `node`, instance `<hostName>:9100`     | fleet node-exporter aspect           |
| Forwarder health | vmagent metrics on `127.0.0.1:8429`, scrape job `vmagent-health`, instance `<hostName>:8429` | `modules/telemetry.nix`              |
| Queue            | `StateDirectory=vmagent` (`/var/lib/vmagent` → `/var/lib/private/vmagent`), 1 GiB per URL    | fleet vmagent contributor            |
| Failure hooks    | `vmagent` and `prometheus-node-exporter` → `notify-event@<unit>.service`, topic `system`     | fleet aspects + `modules/notify.nix` |
| Off, by design   | OTLP admission, `otlp.ingress`, journald shipping, Vector, OTel collector                    | this change                          |

The policy check enforces this shape: `nix flake check --no-build --no-write-lock-file`
evaluates `checks.x86_64-linux.telemetry-policy` (`modules/flake/telemetry-policy.nix`).
It is evaluation-time, not a build step, so a regression fails the canonical
check without building. To force just that check:

```sh
nix eval --no-write-lock-file .#checks.x86_64-linux.telemetry-policy.drvPath
```

It also carries a negative self-test: a probe composition that registers failure
events without the notify aspect must produce hook findings, and the check fails
if that verdict comes back clean.

## Per-host ledger

Status values: **configured** (evaluates and builds), **deployed** (present and
running on the host), **delivering** (evidence at the backend), **pending**
(needs its owner), **n/a** (the lane does not exist on this host).

| #   | Category                                   | Legion     | Spectre    | Owner                           |
| --- | ------------------------------------------ | ---------- | ---------- | ------------------------------- |
| 1   | Evaluated configuration, units, queue path | configured | configured | this repository                 |
| 2   | Fresh node and vmagent-health samples      | pending    | pending    | this repository + backend owner |
| 3   | Journals                                   | n/a        | n/a        | `adopt-fleet-journals`          |
| 4   | Traces                                     | n/a        | n/a        | no producer                     |
| 5   | Allowed/denied access to the metrics route | pending    | pending    | fleet operator                  |
| 6   | Registered-unit failure and alert route    | pending    | pending    | this repository + backend owner |
| 7   | Short destination outage and agent restart | pending    | pending    | this repository                 |

Category 1 evidence (per host):

```sh
systemctl show vmagent -p StateDirectory -p DynamicUser -p User -p Group
systemctl cat vmagent | grep -E 'remoteWrite.url|httpListenAddr|maxDiskUsagePerURL'
systemctl show vmagent prometheus-node-exporter -p OnFailure
ss -ltnp | grep -E '127\.0\.0\.1:(8429|9100)'
ls -ld /var/lib/vmagent /var/lib/private/vmagent
```

Category 2 requires fresh samples with distinct `instance` labels
(`legion:9100`, `legion:8429`, `spectre:9100`, `spectre:8429`) at the backend,
plus the backend owner confirming no _obsolete remote-scrape job_ still collects
these exporters over the network (the local scrape must be the only one).

Category 5 has no workstation ingress to test: the only question is whether the
metrics route accepts these two hosts.

Category 6: exercise an already registered unit failure and, separately, an
existing delivery-health alert rule under operator control, and observe delivery
to the `system` topic. The alert rule owner is the backend operator; do not
invent thresholds here.

Category 7, with operator approval: stop or blackhole the destination, let
buffered data accumulate well below the 1 GiB bound, restart `vmagent`, then
confirm eventual receipt and queue drainage. Keep it short and scoped — never
disrupt the tailnet or SSH, and never fill the real disk. Fleet's offline tests
cover OTLP delivery, not vmagent recovery.

## Series to watch

From the pinned VictoriaMetrics 1.153.0, `127.0.0.1:8429/metrics` exposes real
per-destination series — use these names, do not invent others:

| Concern          | Series                                                                                                                                    |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Backlog          | `vmagent_remotewrite_pending_data_bytes`, `vm_persistentqueue_bytes_pending`, `vmagent_remotewrite_pending_inmemory_blocks`               |
| Queue pressure   | `vmagent_remotewrite_queues`, `vmagent_remotewrite_queue_blocked`, `vmagent_remotewrite_rate_limit_reached_total`                         |
| Send errors      | `vmagent_remotewrite_errors_total`, `vmagent_remotewrite_push_failures_total`, `vmagent_remotewrite_retries_count_total`                  |
| Transport errors | `vmagent_remotewrite_dial_errors_total`, `vmagent_remotewrite_conn_write_errors_total`, `vmagent_remotewrite_send_duration_seconds_total` |
| Dropped data     | `vmagent_remotewrite_packets_dropped_total`, `vmagent_remotewrite_samples_dropped_total`, `vm_persistentqueue_bytes_dropped_total`        |

Known gap to carry to the fleet owner: the pinned vmagent exposes **no**
last-successful-send age or freshness gauge. `vmagent_remotewrite_send_duration_seconds_total`
counts send time (`count` = completed sends) and `vmagent_remotewrite_errors_total`
counts failures, so a destination that accepts nothing while the process stays
up is visible locally only as a growing `pending_data_bytes` plus error
counters. Detecting "the host is silent" therefore needs central missing-data
detection at the backend, not a local watchdog.

Self-health shares the metrics transport: if vmagent cannot deliver, its own
health samples are stuck in the same queue, so a total transport outage is only
visible centrally. A laptop that suspends is not a server outage; do not attach
an unreviewed always-online rule to these hosts.

## Loss modes and rollback

- Bounded, not lossless: 1 GiB per destination, oldest samples dropped at
  capacity. A long outage past the bound loses data.
- Suspend buffers nothing — no metrics are produced while the machine sleeps.
- Queue identity is the destination URL and the `fleet-metrics` name. A
  catalogue coordinate change or destination rename needs a queue-continuity
  review before rollout; resolution is not automatic backlog migration.
- Rollback is the previous generation, or removing both aspect selections. Keep
  queue state: it may hold the only copy of undelivered metrics. Root-snapshot
  rollback can rewind the queue — treat that as a decision, not cleanup.

Adoption is accepted when both hosts' applicable categories pass, or an explicit
deferral is recorded with its owner. Legion first; Spectre stays _configured
only_ until it is reachable and enrolled.
