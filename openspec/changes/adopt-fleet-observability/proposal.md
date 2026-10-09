# Proposal

## Why

Both workstation configurations select the fleet baseline and GC, but neither exported host metrics. The published observability contract provides a remote-write lane that is settled enough to adopt without copying transport machinery. Journals are split into `adopt-fleet-journals`: replay policy, privacy and backend-retention questions are unresolved and under upstream review.

Two things changed after the metrics lane was implemented. The fleet replaced the single `telemetry` aspect with selectable bundles (`telemetry-metrics`, `telemetry-logs`, `telemetry-otlp`) plus realisations, removing `providers.*` and `realized`, so enablement is now expressed by aspect composition and the health registrations are contributed rather than declared by consumers. And a Pi trace producer now exists (`pi-otel`), which puts the trace audience in scope rather than leaving it hypothetical: it resolves to the AI ingress, so full sessions reach the LLM-observability backends.

## What Changes

- Select the fleet `telemetry-metrics` bundle and the `node-exporter` aspect on Legion and Spectre; `telemetry-otlp` is selected only because the Pi trace producer needs a local admission point.
- Send host metrics through one explicitly selected `fleet-metrics` remote-write destination, resolved from the canonical fleet service inventory at the flake-parts boundary. Keep shared policy in a reusable contributor, not in host files.
- Scrape locally only, and rely on the vmagent provider's own loopback health registration rather than declaring one: a running forwarder that is failing to deliver must stay observable.
- Send Pi's traces through the fleet AI ingress: the destination resolves from the canonical inventory to `otel-collector/ai-otlp`, so full sessions — prompts, completions and tool and agent spans — reach VictoriaTraces, Langfuse and Latitude. The general ingress is store-only and is not used for this lane.
- Use stable host labels and vmagent's bounded disk queue. Document behaviour when a portable host loses tailnet access or suspends.
- Record the evaluated queue path in `docs/impermanence.md`, marking it active only after deployment.
- Provide separate configuration, deployment and delivery evidence per host. Endpoint reachability alone is not acceptance.

### Non-goals

No journal shipping and no Vector: the journal lane is `adopt-fleet-journals`. No per-session shaping of what reaches the AI backends: the destination is host-wide, so keeping selected sessions out of Langfuse and Latitude would need an endpoint choice in the producer plus a second route on the fleet side, deferred until a concrete shaping need exists. No dashboards, new alert rules, backend changes, public listeners, Home Manager exporter, home reset, Arch wipe, build/cache adoption or broad input update. Beszel and notify responsibilities remain unchanged.

## Capabilities

### New Capabilities

- `workstation-observability`: host metrics export with canonical destinations, stable identity, local-only exposure, bounded offline buffering, forwarder health visibility and delivery verification.

### Modified Capabilities

None.

## Impact

Extends `modules/telemetry.nix`, adds `modules/node-exporter.nix`, selects the metrics bundle in both host compositions, adds a verification runbook and updates `ARCHITECTURE.md`, `docs/impermanence.md` and the transition task map. The fleet pin moved to `a48a1dcf`, the host-observability revision that appends the node-exporter systemd collector and registers the tailscale daemon's local metrics; the earlier move to `e2a4ac5d` carried the AI ingress published at `6f74d9a2`. Each move touched no other lock node; no new credential or dependency.

Spectre can be configured and evaluated here, but deployment and delivery wait until it is online and its secret enrollment is complete. That does not block independent Legion acceptance.

`upstream-review.md` in this change is a review request to the fleet owner covering both lanes. It is not a dependency of this change. Its orphan-guard item is answered by disposition rather than code: dormant notify registrations staying inert is the approved guarantee, and the consumer-side hook assertion is the evidence.
