# Design

## Context

See `proposal.md`. The source of truth is the adopted nix-fleet revision `a48a1dcf`: `docs/contracts/observability.md`, `docs/contracts/telemetry.md`, `lib/telemetry-contract.nix`, `lib/service-inventory.nix` and the provider modules. Enablement is expressed by composing aspects: `telemetry` is contract-only, `telemetry-metrics`/`-logs`/`-otlp` are the selectable bundles and `telemetry-vmagent`/`-vector`/`-otel-collector-*` are the realisations. `providers.*` and `realized` no longer exist.

`modules/telemetry.nix` only imports the fleet aspect and no host selects it. Both hosts already select notify and Beszel. The node-exporter aspect owns a loopback listener, a local scrape registration and its failure hook; vmagent is activated by the declared scrape work plus a destination. With journald unset, Vector is not activated.

Root stays persistent; this change adds no impermanence mounts or home state. Spectre is installed despite the fleet inventory's stale lifecycle text; its availability and secret enrollment are deployment prerequisites, not reasons to omit configuration.

## Decisions

### 1. Resolve the destination in the contributor's flake-parts scope

Resolve `victoriametrics/remote-write` over the `tailnet` route with `inputs.nix-fleet.lib.serviceEndpoints.url config.fleet` in `modules/telemetry.nix` and pass it into the NixOS aspect by lexical closure, as `modules/notify.nix` does. Aspects read native `networking.hostName`, never a registry key.

Declare `services.telemetry.destinations.fleet-metrics` with `protocol = "prometheus-remote-write"` and `signals = [ "metrics" ]`, and pin `services.telemetry.pipelines.metrics = [ "fleet-metrics" ]` so a later destination cannot silently fan out. Keep the destination name stable. vmagent receives endpoint URLs, so a catalogue URL change or destination rename needs an explicit queue-continuity review; canonical resolution is not automatic backlog migration.

**Alternative:** resolving in both host files repeats identical policy; the contributor pattern is the existing module boundary.

### 2. Reuse the fleet providers

Add `modules/node-exporter.nix` importing the fleet aspect and select it with `telemetry-metrics` in both NixOS aspect lists. No Home Manager aspect. The node aspect supplies `127.0.0.1:9100` and the `hostName:port` instance label; do not replace the target with a fleet hostname. Failure events for node-exporter and vmagent come from their fleet owners and render through the already-selected notify dispatcher; do not register them again.

`telemetry-otlp` is composed as well, because a Pi trace producer now exists and needs a local admission point. That makes `otlp.signals = [ "traces" ]` the correct value rather than the empty list the metrics-only cut used; the trace destination is a separate decision (below).

**Alternative:** OTel for metrics now. The native remote-write lane already owns this path; OTel adds a receiver and a different queue model with no producer.

**Rejected alternative:** staying on the single `telemetry` aspect. It no longer enables anything, so the selection would silently produce no exporter.

### 3. Bounded offline policy

vmagent persists to `/var/lib/vmagent` with the fleet's 1 GiB per-destination budget, dropping the oldest samples at capacity. Its disk budget is provider-owned; do not invent a tuning namespace. Inspect the realised `StateDirectory`/DynamicUser mapping before treating a visible path as a persistence target. Metrics do not exist during suspend, so there is nothing to buffer; long outages evict. Disk budgets do not bound memory. Root-snapshot rollback can rewind queue state; do not purge or restore queues as routine cleanup. Make no lossless-delivery claim.

Update `docs/impermanence.md` with the evaluated path and loss modes. No new home path. `/var/lib/vector` and `/var/lib/opentelemetry-collector` stay planned, not active.

### 4. Observe forwarding health

vmagent's loopback health registration is provider-contributed: the vmagent realisation owns `-httpListenAddr` on `127.0.0.1:8429` and publishes `services.telemetry.scrape.vmagent-health` with `healthPort = 8429`, `healthJob = "vmagent-health"` and `labels.instance = "<hostName>:vmagent"`. The consumer must not declare it again — a second registration duplicates ownership and an explicit `labels.instance` of our own would conflict. The registry option stays the stable surface for assertions: read `services.telemetry.scrape.vmagent-health` and the rendered listener, not generated unit internals.

Route it through the same pipeline. Inventory the pinned version's backlog, send/error and dropped-data series and require fresh backend samples. If a needed signal is missing, record the gap for the fleet owner rather than inventing a metric name. No watchdog process; no health endpoint off loopback.

The backend owner identifies existing delivery-health alert rules and the system-topic route; missing coverage is an owned acceptance gap. This repository invents no thresholds. Laptop suspend must not read as a server outage under an unreviewed always-online rule. Self-health shares the metrics transport, so a total transport outage needs central missing-data detection.

### 5. Verify delivery, not just configuration

Add an evaluation-time policy check owned by the telemetry contributor, failing within `nix flake check --no-build --no-write-lock-file`. For both hosts: exact destination and pipeline, signal scope, loopback node and health listeners, distinct instance labels, effective failure hooks through notify, trace admission that is local and traces-only, the trace destination resolved from the inventory rather than written locally, and Vector not enabled. Include a negative case for an ineffective notify composition (registrations without notify). Validate built unit files for package-provided units.

Runbook `docs/runbooks/verify-workstation-observability.md` keeps a per-host configured/deployed/delivering ledger over the applicable fleet acceptance categories:

1. Evaluated configuration, effective units/hooks and the realised queue path.
2. Fresh node and vmagent-health metrics with distinct host/job labels; the backend owner removes any obsolete remote-scrape job so the exporter is not collected twice.
3. Journals: not applicable here (see `adopt-fleet-journals`).
4. Traces: the local admission point and the resolved fleet destination are recorded, but delivery is not accepted here — the destination decision is deferred (below).
5. Fleet operator confirms allowed/denied access to the metrics route. No workstation ingress exists to test.
6. An existing registered-unit failure and existing alert route exercised under operator control.
7. A short controlled destination outage and agent restart below capacity: eventual receipt, queue drainage, observable error/backlog signals. No whole-tailnet or SSH disruption, no saturation of the real disk.

External checks stay pending until their owner supplies evidence. Fleet's offline tests cover OTLP, not vmagent recovery.

### 6. The trace destination is the AI ingress

Pi's `pi-otel` producer admits traces locally and the contributor resolves the fleet destination through the inventory. That destination is the AI ingress — `otel-collector/ai-otlp` over tailnet, published at nix-fleet `6f74d9a2` as `http://home-forge:4319` — not the general record, which resolves to `http://home-forge:4318` and is store-only. Runtime evidence from the fleet owner (2026-10-09, collector 0.155.0 on the gateway host): a synthetic trace posted to 4318 appeared in VictoriaTraces and in neither Langfuse nor Latitude; one posted to 4319 appeared in all three.

**Why the AI ingress.** Pi sessions belong in the LLM-observability backends: Latitude is the failure-triage console and Langfuse the LLM-observability view, and both read best when tool and agent spans travel with the LLM calls. Sending only the LLM calls would hand them a fragment, and the lane exists (fleet D-083) for full agent sessions. Full capture means prompts, completions and tool I/O.

**Accepted consequence.** The AI ingress has no admission check, so it is routing separation rather than an authenticated boundary — anything on the tailnet can post to it. That is a statement about who can post, not about whether these sessions belong there.

**Rejected alternative:** staying on the general ingress. It would leave the traces in the trace store and out of both LLM backends, contradicting what `ARCHITECTURE.md` already claimed.

**Deferred alternative:** a per-session split, with some sessions kept out of Langfuse and Latitude. This is not a destination toggle — Pi has one host-wide destination, so it would need the extension to choose an endpoint per session. Until a concrete shaping need exists, the general ingress remains the place for traffic that must not reach those backends.

**If payload shaping is ever wanted**, the fleet's own mechanism is sibling trace pipelines on one route receiver rather than a second route: destination-specific output views let a mixed producer send a lean operational copy to the trace store and rich copies to its AI backends from the same route. Two obligations come with it — every destination must be declared in the route so the fleet renders its exporter, credentials and delivery state, and the rendered receiver/processor/exporter assignments must be inspected afterwards, because a native `settings` override makes the pipelines rather than the route declaration decide effective routing. Nothing here needs it: one destination on the AI route, with the gateway's own fanout, already delivers the rich stream to all three backends and gives each selected destination exactly one output path.

Until the switch: hardcode no URL, do not infer AI eligibility from backend presence, and treat 4319 as routing rather than access control.

## Risks / Trade-offs

- **Bounded loss on long outages** → provider budgets, documented eviction, short-outage tests only.
- **Backend-dependent acceptance** → evidence from the fleet operator; pending stays pending.
- **Duplicate collection** → local scrape plus any central scrape of the same exporter; backend owner checks.
- **Queue identity on URL changes** → continuity review before relock moves coordinates.
- **Trace destination was general-lane** → resolved: the lane now resolves to the AI ingress, so Pi spans reach Langfuse and Latitude as `ARCHITECTURE.md` claims. The residual risk is the reverse substitution — pointing it back at the general ingress would silently stop the LLM backends receiving anything, so the policy check pins the expected endpoint.
- **Spectre unavailable or unenrolled** → evaluate both, deploy Legion first, record Spectre as configured until independently checked.

## Migration Plan

1. Implement contributor, host selection, checks and runbook without touching pins or unrelated work.
2. Build Legion; after explicit approval switch and complete its categories and persistence inventory.
3. Deploy Spectre when reachable and enrolled; repeat with its own instance.
4. Roll back via the prior generation or by removing both selections. Keep queued state until delivery or disposal is a deliberate decision.
5. Mark metrics adoption accepted when both hosts' applicable categories pass, or an explicit, owned deferral is recorded.
