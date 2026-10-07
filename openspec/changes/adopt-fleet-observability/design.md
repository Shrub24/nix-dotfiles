# Design

## Context

See `proposal.md` for scope and motivation. The source of truth is nix-fleet revision `23411143acdacf676e49ce7d68bd5fd6d57ec47d`, especially `docs/contracts/observability.md`, `docs/contracts/telemetry.md`, `lib/telemetry-contract.nix` and the provider modules.

`modules/telemetry.nix` currently only imports the fleet aspect; neither host selects it. Both hosts already select notify and Beszel. The node-exporter aspect owns a loopback listener, a local scrape registration and its failure hook. Telemetry supplies vmagent for remote write and Vector for journals. Selection and declared work activate providers; a destination alone does not.

Both hosts can be portable. Root remains persistent; this change must not add impermanence mounts or move home state. Spectre is installed, despite the fleet inventory's stale lifecycle description. Its current availability and secret enrollment are separate deployment prerequisites, not reasons to omit it from configuration.

## Goals / Non-Goals

**Goals:** one shared contributor, thin host selection, canonical destinations, a reviewed system-unit allowlist, and independently verifiable delivery per host.

**Non-goals:** a new transport implementation, user-service journal matching, OTLP admission, remote node scraping or changes to fleet backends/ACLs. No new credential is needed for the current tailnet routes.

## Decisions

### 1. Resolve destinations in the contributor's flake-parts scope

Extend `modules/telemetry.nix` to resolve these selectors through `inputs.nix-fleet.lib.serviceEndpoints.url config.fleet`:

| Lane     | Service           | Endpoint       | Route     | Consumer setting                                         |
| -------- | ----------------- | -------------- | --------- | -------------------------------------------------------- |
| Metrics  | `victoriametrics` | `remote-write` | `tailnet` | `services.telemetry.destinations.fleet-metrics.endpoint` |
| Journals | `victorialogs`    | `jsonline`     | `tailnet` | `services.telemetry.journald.sink.endpoint`              |

Pass the resolved values into its NixOS aspect through lexical closure, following `modules/notify.nix`. The reusable aspect reads native `networking.hostName` and `config.currentHost.primaryUser`, not a named registry entry. No argument bus or new per-host telemetry URL option is needed.

The metrics destination uses `protocol = "prometheus-remote-write"` and `signals = [ "metrics" ]`. It is the only metrics destination. Keep the destination name stable because it identifies on-disk queue state. Journals use their own sink, not a telemetry destination or the trace gateway.

**Alternative:** resolving separately in both host files repeats identical service policy. The existing contributor pattern already provides the correct module boundary.

### 2. Use the fleet providers and exporter registration unchanged

Publish a thin `node-exporter` contributor in `modules/node-exporter.nix`, importing the fleet aspect. Both hosts select it alongside `telemetry` in their NixOS aspect lists. No Home Manager aspect is added.

Use vmagent for `providers.prometheusScrape` and Vector for `providers.journaldIngest`. Keep `otlp.signals` empty, ingress unset and trace destinations absent; do not read the disabled OTLP URL. The node aspect supplies `127.0.0.1:9100` and the `hostName:port` instance label. Do not replace its target with a fleet hostname.

The node-exporter, vmagent and Vector failure events come from their fleet owners. Verify that they render through the already-selected notify dispatcher; do not register them a second time. Preserve the existing system topic.

**Alternative:** use OTel for metrics and logs now. The fleet's native remote-write and JSON-line lanes already own these paths, while OTel would introduce an unnecessary receiver and a different queue model before a trace producer exists.

### 3. Start with a concrete system-unit policy

Set `journald.enable = true` and a non-empty `includeUnits` using full system-unit names. Proposed shared list:

- `sshd.service`: remote access failures.
- `NetworkManager.service`, `systemd-resolved.service`, `tailscaled.service`: connectivity and tailnet diagnostics.
- `nix-daemon.service`, `fast-nix-gc.service`, `nix-gc-roots.service`: build and store-maintenance failures.
- `beszel-agent.service`, `notify.service`, `prometheus-node-exporter.service`: monitoring and dispatch health.
- `greetd.service`: login service health, not the user's desktop session.
- `home-manager-${primaryUser.name}.service`: system-owned activation failures, using the current-host projection.

Legion additionally selects `snapper-timeline.service`, `snapper-cleanup.service` and `syncthing.service`. These additions remain in the host policy beside the services it owns. Spectre gets no Legion-only units. Verify membership against each evaluated configuration; do not silently filter missing names, which would conceal drift.

Forwarders' own logs remain local initially; notify still covers vmagent/Vector failures. NikS3 units remain outside this initial list until the in-flight uploader-to-publisher migration has settled its unit names. No wildcard or whole notify-event registry is copied into the allowlist.

The trusted match is `_SYSTEMD_UNIT`, not a logger tag. Do not include `user@<uid>.service`, desktop units or a Home Manager user service name: selecting the user manager would sweep in unrelated user logs, and this fleet interface does not express an individual `_SYSTEMD_USER_UNIT` filter. Grist, QMD, MCP, Surge, Pi and desktop journals therefore stay local.

An allowlist is not redaction. Networking and activation logs can contain usernames, addresses, SSIDs, VPN coordinates, paths or application error output. Pending journal buffers contain copies too. Review this proposed list before the first journal-enabled switch; if a selected unit can print credentials, narrow the list rather than promise generic scrubbing.

**Alternative:** ship all journals or derive the list from notify registrations. Both let future unrelated services expand collection without a deliberate privacy decision.

### 4. Keep the fleet's bounded offline policy

| Agent   | Persistent state   | Budget                | Full-buffer behaviour         |
| ------- | ------------------ | --------------------- | ----------------------------- |
| vmagent | `/var/lib/vmagent` | 1 GiB per destination | Drops oldest buffered samples |
| Vector  | `/var/lib/vector`  | 512 MiB               | Blocks journal reading        |

Set the journal budget and `whenFull = "block"` explicitly. Do not tune vmagent by inventing a public namespace; its disk budget is provider-owned. Preserve service-managed permissions and inspect the realised `StateDirectory`/DynamicUser mapping before treating a visible path as a persistence mount target.

Queue data survives agent restart because root stays persistent. Metrics during suspend do not exist to buffer. Long outages can evict metrics or rotate unread journals; the reader's current-boot policy also limits historical replay after reboot. Do not claim exactly-once or unlimited lossless recovery. Preserve destination identity during rollback/reconfiguration.

Update `docs/impermanence.md` with evaluated state paths and these loss modes. No new durable home paths are introduced. `/var/lib/opentelemetry-collector` remains planned, not active, because no collector is needed for this change.

**Alternative:** discard newest journals at capacity. Blocking preserves the pending buffer and lets journald absorb a short outage, but only within its retention window. The chosen limits bound storage use on both laptops.

### 5. Verify delivery, not merely the configuration

Add a focused evaluation regression check owned by the telemetry contributor. Check both host configurations for aspect selection, exact destinations, signal scope, exporter loopback binding, distinct instance labels, non-empty unit membership, effective failure hooks and disabled trace ingress. Execute that check as well as `nix flake check --no-build --no-write-lock-file`; the latter evaluates derivations rather than running delivery tests.

Create `docs/runbooks/verify-workstation-observability.md` with a per-host configured/deployed/delivering ledger and the fleet's seven acceptance categories:

1. Inspect evaluated configuration, effective units/hooks and actual queue storage. Persistent root satisfies present storage retention; no reset-root mounts are required.
2. Query fresh node metrics with the expected instance. The backend owner checks/removes obsolete remote-scrape jobs if any exist, so the local exporter is not collected twice.
3. Observe a unique marker from an allowed system unit; verify distinct excluded-system and user-service markers are absent after the positive path delivers. Use a temporary, explicitly allowlisted system probe if needed, restore the production list afterward, and never substitute `logger -t` for trusted unit metadata.
4. Mark trace delivery not applicable: no producer, receiver or destination is enabled.
5. Have the fleet operator confirm allowed/denied access to the selected backend routes. Consumer listeners are loopback-only; do not test a nonexistent workstation ingress or alter fleet ACLs here.
6. Exercise an existing registered-unit failure and existing backend alert route under operator control. Verify the existing system topic; do not add an alert rule merely for this rollout.
7. Exercise a short, controlled destination outage and agent restart with tagged data below capacity. Verify eventual receipt, queue drainage and unchanged limits. Restrict the outage to the forwarding process/test lane: do not disconnect the whole tailnet, stop SSH or fill production queues to capacity.

Record external checks as pending until their owner supplies evidence. Existing fleet offline tests cover OTLP, not runtime vmagent/Vector recovery, so they are not substitutes for categories 2, 3 or 7.

## Risks / Trade-offs

- **Sensitive payloads** → narrow system-unit collection, exclude user-session wrappers, review before deployment and document buffer copies. No redaction guarantee.
- **Bounded loss during long offline periods** → retain provider budgets, document eviction/rotation/boot-boundary loss, and test short outages without saturating the real disk.
- **Silent unit-name mismatch** → evaluation checks require listed services to exist; apply after concurrent unit migrations settle or leave affected units excluded.
- **Backend-dependent acceptance** → obtain query and network/alert evidence from the fleet operator. Pending external evidence stays pending.
- **Spectre unavailable or not enrolled** → evaluate both, deploy Legion first, and record Spectre as configured until independently checked. Its unbound SSH inventory key is not itself a metrics/journal enrollment mechanism.

## Migration Plan

1. Implement contributor policy, host selection, evaluation checks and the runbook without changing input pins or unrelated pending work.
2. Build Legion's configuration and review the effective allowlist before an explicitly authorised switch. Complete its delivery categories and persistence inventory.
3. Deploy Spectre only when reachable and its existing switch prerequisites are met; repeat the same checks with its own instance and smaller unit set.
4. Roll back a host through its prior NixOS generation, or remove both new aspect selections and switch. Keep queued state until delivery or disposal is a deliberate decision; do not delete it as cleanup.
5. Mark the transition telemetry item complete only when both hosts' applicable acceptance categories are satisfied or a remaining host deferral is explicitly accepted. Trace adoption stays separate.
